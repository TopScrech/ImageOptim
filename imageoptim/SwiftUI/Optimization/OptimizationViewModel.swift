import SwiftUI

@Observable
final class OptimizationViewModel {
    var results: [OptimizationResult] { filesController?.arrangedObjects.map(OptimizationResult.init) ?? [] }
    var selection: Set<URL> = [] {
        didSet { synchronizeSelection() }
    }
    var isImporting = false
    var showsError = false
    var errorMessage: String? {
        didSet { showsError = errorMessage != nil }
    }
    var previewURL: URL?
    var isBusy: Bool { filesController?.isBusy ?? false }
    var canStop: Bool { filesController?.isStoppable ?? false }
    var canRevert: Bool { filesController?.canRevert ?? false }
    var canOptimizeAgain: Bool { filesController?.canStartAgainOptimized(false) ?? false }
    var canOptimizeSmaller: Bool { filesController?.canStartAgainOptimized(true) ?? false }
    var canClearCompleted: Bool { filesController?.canClearComplete ?? false }
    var originalBytes: Int64 { completedJobs.reduce(0) { $0 + ($1.byteSizeOriginal ?? 0) } }
    var bytesSaved: Int64 {
        completedJobs.reduce(0) { $0 + max(0, ($1.byteSizeOriginal ?? 0) - ($1.byteSizeOptimized ?? 0)) }
    }
    private var delegate: ImageOptimController?
    private var undoManager: UndoManager?
    private var filesController: FilesController? { delegate?.filesController }
    private var completedJobs: [JobProxy] {
        filesController?.arrangedObjects.filter {
            $0.isDone && !$0.isFailed && ($0.byteSizeOriginal ?? 0) > 0 && ($0.byteSizeOptimized ?? 0) > 0
        } ?? []
    }

    func connect(to delegate: ImageOptimController) {
        filesController?.onFilesChanged = nil
        self.delegate = delegate
        delegate.filesController.undoManager = undoManager
        delegate.filesController.onFilesChanged = { [weak self] in
            self?.synchronizeSelection()
        }
        synchronizeSelection()
    }

    private func synchronizeSelection() {
        guard let filesController else { return }
        let jobs = filesController.arrangedObjects
        let validSelection = selection.intersection(jobs.map(\.filePath))
        if selection != validSelection {
            selection = validSelection
        }
        filesController.setSelectedObjects(jobs.filter { selection.contains($0.filePath) })
    }

    func add(_ urls: [URL]) {
        guard let controller = delegate?.filesController else { return }
        controller.setRow(-1)
        if !controller.add(urls) {
            errorMessage = String(localized: "Some files could not be opened")
        }
    }

    func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls): add(urls)
        case .failure(let error): errorMessage = error.localizedDescription
        }
    }

    func stop() {
        delegate?.filesController.stopSelected()
    }

    func optimizeAgain(optimizedOnly: Bool = false) {
        delegate?.filesController.startAgainOptimized(optimizedOnly)
    }

    func revert() {
        delegate?.filesController.revert()
    }

    func clearCompleted() {
        delegate?.filesController.clearComplete()
    }

    func removeSelected() {
        guard let controller = delegate?.filesController else { return }
        let jobs = controller.arrangedObjects
        controller.remove(contentsOf: jobs.filter { selection.contains($0.filePath) })
    }

    func preview() {
        previewURL = results.first { selection.contains($0.id) }?.id
    }

    func reveal() {
        delegate?.revealURLs(results.filter { selection.contains($0.id) }.map(\.id))
    }

    func setUndoManager(_ undoManager: UndoManager?) {
        self.undoManager = undoManager
        delegate?.filesController.undoManager = undoManager
    }

    func copyFiles() {
        delegate?.copySelectedFiles()
    }

    func copyDataURLs() {
        delegate?.copySelectedDataURLs()
    }

    func pasteFiles() {
        delegate?.pasteFiles()
    }
}
