import Foundation

@MainActor
@Observable
public final class Job {
    public private(set) var filePath: URL
    public var displayName: String
    public private(set) var isBusy = false
    public private(set) var isDone = false
    public private(set) var isFailed = false
    public private(set) var statusText: String? = String(localized: "Waiting to be optimized")
    public private(set) var bestToolName: String?
    public private(set) var initialInput: File?
    public private(set) var unoptimizedInput: File?
    public private(set) var savedOutput: File?
    public private(set) var revertFile: File?
    private var workingInput: File?
    private var toolResults: [String: (size: UInt, ratio: Double)] = [:]
    private var lastContentHash: String?
    private var lossyConverted = false
    private var stopping = false
    private var discardResult = false
    @ObservationIgnored private let database: ResultsDb?
    @ObservationIgnored var task: Task<Void, Never>?
    @ObservationIgnored private var runner: CommandWorker?

    public init(filePath: URL, resultsDatabase: ResultsDb?) {
        self.filePath = filePath
        database = resultsDatabase
        displayName = FileManager.default.displayName(atPath: filePath.path)
    }

    public var isOptimized: Bool {
        guard let original = unoptimizedInput, let output = workingInput ?? savedOutput else { return false }
        return output.byteSize < original.byteSize
    }
    
    public var isStoppable: Bool { isBusy && !isDone }
    public var canRevert: Bool { revertFile != nil && isDone && !isBusy }
    public var byteSizeOriginal: Int64? { initialInput.map { Int64($0.byteSize) } }
    public var byteSizeOptimized: Int64? { (workingInput ?? savedOutput ?? unoptimizedInput).map { Int64($0.byteSize) } }

    func prepare() {
        isBusy = true
        isDone = false
        isFailed = false
        stopping = false
        discardResult = false
        statusText = String(localized: "Waiting to be optimized")
    }

    func run(settings: OptimizationSettings, fileLimiter: AsyncLimiter, guetzliLimiter: AsyncLimiter) async {
        let directory = URL.temporaryDirectory.appending(path: "ImageOptim.\(UUID().uuidString)", directoryHint: .isDirectory)
        do {
            try Task.checkCancellation()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            statusText = String(localized: "Inspecting file")
            await fileLimiter.acquire()
            let input: File
            let inputHash: String
            let contentHash: String
            let repeated: Bool
            
            do {
                input = try await FileOperations.read(filePath)
                contentHash = try await FileOperations.hash(filePath, settings: "")
                repeated = lastContentHash == contentHash
                inputHash = try await FileOperations.hash(filePath, settings: settings.cacheIdentifier)
                fileLimiter.release()
            } catch {
                fileLimiter.release()
                throw error
            }
            
            try Task.checkCancellation()
            
            if !repeated {
                initialInput = input
                revertFile = nil
                savedOutput = nil
                bestToolName = nil
                toolResults.removeAll()
                lossyConverted = false
            }
            
            unoptimizedInput = input
            let stagedInput = directory.appending(path: "input." + (input.fileType == .svg ? "svg" : "image"))
            try await FileOperations.copy(input.path, to: stagedInput)
            workingInput = input.at(stagedInput)
            let optimizers = Optimizer.plan(for: input.fileType, settings: settings, repeated: repeated, lossyConverted: lossyConverted)
            
            guard !optimizers.isEmpty else {
                throw CocoaError(.executableNotLoadable, userInfo: [NSLocalizedDescriptionKey: "All necessary tools have been disabled in Preferences"])
            }
            
            let cacheKey = inputHash + (repeated ? "-repeat" : "-first")
            lastContentHash = contentHash
            
            if database?.contains(cacheKey) != true {
                for optimizer in optimizers {
                    if stopping || Task.isCancelled { break }
                    guard let current = workingInput else { break }
                    statusText = String(localized: "Started \(optimizer.name)")
                    let command = CommandWorker()
                    runner = command
                    let serialize = optimizer.executable == "guetzli" && current.isLarge
                    
                    if serialize {
                        await guetzliLimiter.acquire()
                    }
                    
                    do {
                        try Task.checkCancellation()
                        let output = directory.appending(path: UUID().uuidString + "." + (input.fileType == .svg ? "svg" : "temp"))
                        
                        if let result = try await optimizer.optimize(current, output: output, settings: settings, repeated: repeated, runner: command) {
                            workingInput = result
                            updateBestTool(optimizer.name, previous: current.byteSize, result: result.byteSize)
                            if optimizer.quality < 100 { lossyConverted = true }
                        }
                    } catch is CancellationError {
                        stopping = true
                    } catch {
                        if !stopping && !Task.isCancelled {
                            isFailed = true
                            statusText = error.localizedDescription
                        }
                    }
                    
                    if serialize { guetzliLimiter.release() }
                    runner = nil
                }
            }
            
            if !discardResult, let output = workingInput, output.byteSize < input.byteSize {
                await fileLimiter.acquire()
                
                do {
                    let savedHash = try await FileOperations.hash(output.path, settings: "")
                    let backup = try await FileOperations.save(output, over: input, settings: settings, expectedHash: inputHash)
                    fileLimiter.release()
                    
                    if revertFile == nil {
                        revertFile = input.at(backup)
                    } else {
                        await FileOperations.remove(backup.deletingLastPathComponent())
                    }
                    
                    savedOutput = output.at(filePath)
                    lastContentHash = savedHash
                    isFailed = false
                    statusText = String(localized: "Optimized successfully with \(bestToolName ?? "PicPress")")
                } catch {
                    fileLimiter.release()
                    throw error
                }
            } else if !isFailed {
                statusText = stopping || Task.isCancelled ? String(localized: "Stopped") : String(localized: "File cannot be optimized any further")
                if !stopping && !Task.isCancelled && !discardResult { database?.insert(cacheKey) }
            }
        } catch is CancellationError {
            statusText = String(localized: "Stopped")
        } catch {
            isFailed = true
            statusText = error.localizedDescription
        }
        
        workingInput = nil
        await FileOperations.remove(directory)
        runner = nil
        isDone = true
        isBusy = false
        stopping = false
        task = nil
    }

    private func updateBestTool(_ name: String, previous: UInt, result: UInt) {
        toolResults[name] = (result, Double(previous) / Double(result))
        let smallest = toolResults.min { $0.value.size < $1.value.size }?.key
        let largestGain = toolResults.max { $0.value.ratio < $1.value.ratio }?.key
        if let smallest, let largestGain, smallest != largestGain {
            bestToolName = "\(largestGain) + \(smallest)"
        } else {
            bestToolName = smallest
        }
    }

    @discardableResult public func stop() -> Bool {
        guard isStoppable else { return false }
        stopping = true
        task?.cancel()
        runner?.cancel()
        return true
    }

    public func cleanup() {
        discardResult = true
        _ = stop()
    }

    @discardableResult public func revert() -> Bool {
        guard canRevert, let backup = revertFile else { return false }
        do {
            let data = try Data(contentsOf: backup.path)
            guard data.count == backup.byteSize else { return false }
            try FileOperations.restore(backup.path, to: filePath)
            try? FileManager.default.removeItem(at: backup.path.deletingLastPathComponent())
            let restored = backup.at(filePath)
            initialInput = restored
            unoptimizedInput = restored
            savedOutput = nil
            revertFile = nil
            bestToolName = nil
            toolResults.removeAll()
            lossyConverted = false
            lastContentHash = nil
            isFailed = false
            statusText = String(localized: "Reverted to original")
            return true
        } catch {
            statusText = error.localizedDescription
            return false
        }
    }
}
