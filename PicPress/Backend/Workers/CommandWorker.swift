import Foundation

@MainActor
final class CommandWorker {
    private var process: Process?
    private var timer: Task<Void, Never>?

    func run(executable: URL, arguments: [String], input: URL? = nil, output: URL? = nil,
             timeout: Int? = nil, lowPriority: Bool) async throws -> Int32 {
        try Task.checkCancellation()
        let process = Process()
        self.process = process
        process.executableURL = executable
        process.currentDirectoryURL = executable.deletingLastPathComponent()
        process.arguments = arguments
        process.qualityOfService = lowPriority ? .utility : .userInitiated
        // Never inherit NODE_OPTIONS, NODE_PATH, or dynamic-loader overrides
        process.environment = [
            "PATH": "/usr/bin:/bin",
            "HOME": NSHomeDirectory(),
            "TMPDIR": URL.temporaryDirectory.path,
            "NSUnbufferedIO": "YES"
        ]
        let inputHandle = try input.map { try FileHandle(forReadingFrom: $0) }
        let outputHandle = try output.map {
            try Data().write(to: $0)
            return try FileHandle(forWritingTo: $0)
        }
        defer {
            try? inputHandle?.close()
            try? outputHandle?.close()
            timer?.cancel()
            timer = nil
            self.process = nil
        }
        process.standardInput = inputHandle ?? .nullDevice
        process.standardOutput = outputHandle ?? .nullDevice
        process.standardError = FileHandle.nullDevice
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { process in
                    continuation.resume(returning: process.terminationStatus)
                }
                do {
                    try process.run()
                    if lowPriority { setpriority(PRIO_PROCESS, UInt32(process.processIdentifier), 10) }
                    if let timeout {
                        timer = Task { [weak self] in
                            do { try await Task.sleep(for: .seconds(timeout)) } catch { return }
                            if let process = self?.process, process.isRunning { process.interrupt() }
                        }
                    }
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancel() }
        }
    }

    func cancel() {
        guard let process, process.isRunning else { return }
        process.terminate()
        timer?.cancel()
        timer = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            if let process = self?.process, process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
    }

    static func resourceBundle() throws -> Bundle {
        // Xcode may load the backend from outside the sandboxed app bundle
        let main = Bundle.main
        let application: Bundle?
        if main.bundleURL.pathExtension == "appex" {
            application = Bundle(url: main.bundleURL.deletingLastPathComponent()
                .deletingLastPathComponent().deletingLastPathComponent())
        } else {
            application = main
        }
        guard let frameworks = application?.privateFrameworksURL,
              let bundle = Bundle(url: frameworks.appending(path: "ImageOptimGPL.framework")) else {
            throw CocoaError(.executableNotLoadable, userInfo: [NSLocalizedDescriptionKey: "The bundled optimization framework is missing"])
        }
        return bundle
    }

    static func executable(_ name: String) throws -> URL {
        let bundle = try resourceBundle()
        guard let url = bundle.url(forAuxiliaryExecutable: name) ?? bundle.url(forResource: name, withExtension: nil),
              FileManager.default.isExecutableFile(atPath: url.path) else {
            throw CocoaError(.executableNotLoadable, userInfo: [NSLocalizedDescriptionKey: String(localized: "\(name) failed to start", bundle: #bundle)])
        }
        return url
    }
}
