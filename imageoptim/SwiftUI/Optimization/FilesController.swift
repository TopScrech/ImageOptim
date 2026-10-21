import SwiftUI
import ImageOptimGPL

@Observable
final class FilesController {
    private(set) var arrangedObjects: [JobProxy] = [] {
        didSet { onFilesChanged?() }
    }
    var onFilesChanged: (() -> Void)?
    var selectedObjects: [JobProxy] = []
    var undoManager: UndoManager?
    var onQueueFinished: (() -> Void)?
    private(set) var isBusy = false
    var isStoppable: Bool {
        !scans.isEmpty || !pendingDirectories.isEmpty || arrangedObjects.contains { $0.isStoppable }
    }
    private var queue: JobQueue?
    private var database: ResultsDb?
    private var isEnabled = false
    private var scans: [UUID: Task<Void, Never>] = [:]
    private var pendingDirectories: [URL] = []
    private var scanLimit = 1

    func configure() {
        let defaults = UserDefaults.standard
        scanLimit = max(1, defaults.integer(forKey: "RunConcurrentDirscans"))
        database = ResultsDb()
        queue = JobQueue(cpus: defaults.integer(forKey: "RunConcurrentFiles"),
                         files: defaults.integer(forKey: "RunConcurrentFileops"), defaults: defaults)
        isEnabled = true
        queue?.onBusyChanged = { [weak self] in
            guard let self, self.isEnabled else { return }
            self.updateBusyState()
        }
        updateBusyState()
    }

    var queueCount: Int { (queue?.queueCount() ?? 0) + scans.count + pendingDirectories.count }
    var canRevert: Bool { selectedObjects.contains { $0.canRevert } }
    var canClearComplete: Bool { arrangedObjects.contains { $0.isDone } }

    func setSelectedObjects(_ jobs: [JobProxy]) { selectedObjects = jobs }

    func cleanup() {
        isEnabled = false
        queue?.onBusyChanged = nil
        for task in scans.values { task.cancel() }
        scans.removeAll()
        pendingDirectories.removeAll()
        queue?.cleanup()
        for proxy in arrangedObjects { proxy.job.cleanup() }
    }

    @discardableResult
    func addPaths(_ paths: [String]) -> Bool { add(paths.map { URL(filePath: $0) }) }

    @discardableResult
    func add(_ urls: [URL]) -> Bool {
        guard isEnabled, let queue else { return false }
        var allSucceeded = true
        var additions: [JobProxy] = []
        for url in urls {
            let path = url.resolvingSymlinksInPath()
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory) else {
                allSucceeded = false
                continue
            }
            if isDirectory.boolValue {
                scan(path)
            } else if let existing = (arrangedObjects + additions).first(where: { $0.filePath == path }) {
                if !existing.isBusy { queue.add(existing.job) }
            } else {
                let job = Job(filePath: path, resultsDatabase: database)
                let proxy = JobProxy(job: job)
                additions.append(proxy)
                queue.add(job)
            }
        }
        addJobObjects(additions)
        updateBusyState()
        return allSucceeded
    }

    private func scan(_ path: URL) {
        guard scans.count < scanLimit else {
            pendingDirectories.append(path)
            return
        }
        let id = UUID()
        let extensions = enabledExtensions
        scans[id] = Task { [weak self] in
            for await batch in DirectoryScanner.files(in: path, extensions: extensions) {
                guard !Task.isCancelled else { break }
                self?.add(batch)
            }
            guard let self else { return }
            scans[id] = nil
            if isEnabled, !pendingDirectories.isEmpty { scan(pendingDirectories.removeFirst()) }
            updateBusyState()
        }
    }

    private func addJobObjects(_ jobs: [JobProxy]) {
        guard !jobs.isEmpty else { return }
        undoManager?.registerUndo(withTarget: self) { $0.remove(contentsOf: jobs) }
        undoManager?.setActionName(String(localized: "Add", comment: "undo command name"))
        arrangedObjects.append(contentsOf: jobs)
    }

    func remove(contentsOf jobs: [JobProxy]) {
        guard !jobs.isEmpty else { return }
        undoManager?.registerUndo(withTarget: self) { $0.addJobObjects(jobs) }
        undoManager?.setActionName(String(localized: "Remove", comment: "undo command name"))
        for job in jobs { _ = job.stop() }
        let ids = Set(jobs.map(\.filePath))
        arrangedObjects.removeAll { ids.contains($0.filePath) }
        selectedObjects.removeAll { ids.contains($0.filePath) }
    }

    func stop() {
        for task in scans.values { task.cancel() }
        scans.removeAll()
        pendingDirectories.removeAll()
        for job in arrangedObjects { _ = job.stop() }
        updateBusyState()
    }

    func revert() {
        var failed = false
        for job in selectedObjects { if !job.revert() { failed = true } }
        if failed { NSSound.beep() }
    }

    func clearComplete() {
        remove(contentsOf: arrangedObjects.filter { $0.isDone })
    }

    func canStartAgainOptimized(_ optimizedOnly: Bool) -> Bool {
        let jobs = selectedObjects.isEmpty ? arrangedObjects : selectedObjects
        return jobs.contains { !$0.isBusy && (!optimizedOnly || $0.isOptimized) }
    }

    func startAgainOptimized(_ optimizedOnly: Bool) {
        let jobs = selectedObjects.isEmpty ? arrangedObjects : selectedObjects
        var started = false
        for job in jobs where !job.isBusy && (!optimizedOnly || job.isOptimized) {
            queue?.add(job.job)
            started = true
        }
        if !started { NSSound.beep() }
        updateBusyState()
    }

    private func updateBusyState() {
        let wasBusy = isBusy
        isBusy = queueCount > 0
        if wasBusy && !isBusy { onQueueFinished?() }
    }

    private var enabledExtensions: Set<String> {
        let defaults = UserDefaults.standard
        var extensions: Set<String> = []
        if ["PngCrush2Enabled", "PngOutEnabled", "OptiPngEnabled", "AdvPngEnabled", "ZopfliEnabled"].contains(where: defaults.bool(forKey:)) {
            extensions.insert("png")
        }
        if ["JpegOptimEnabled", "JpegTranEnabled"].contains(where: defaults.bool(forKey:)) {
            extensions.formUnion(["jpg", "jpeg"])
        }
        if defaults.bool(forKey: "GifsicleEnabled") { extensions.insert("gif") }
        if defaults.bool(forKey: "SvgoEnabled") || defaults.bool(forKey: "SvgcleanerEnabled") { extensions.insert("svg") }
        return extensions.isEmpty ? ["png"] : extensions
    }
}
