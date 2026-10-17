import SwiftUI

@Observable
final class OptimizationViewModel {
    var results: [OptimizationResult] = []
    var selection: Set<URL> = []
    var isImporting = false
    var showsError = false
    var errorMessage: String? {
        didSet { showsError = errorMessage != nil }
    }
    var previewURL: URL?
    var isBusy = false
    var canStop = false
    var canRevert = false
    var canOptimizeAgain = false
    var canOptimizeSmaller = false
    var canClearCompleted = false
    var bytesSaved: Int64 = 0
    var originalBytes: Int64 = 0
    private var delegate: ImageOptimController?
    private var undoManager: UndoManager?

    func connect(to delegate: ImageOptimController) async {
        self.delegate = delegate
        delegate.filesController.undoManager = undoManager
        while !Task.isCancelled {
            refresh()
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
        }
    }

    func refresh() {
        guard let controller = delegate?.filesController else { return }
        let jobs = controller.arrangedObjects
        let updatedResults = jobs.map(OptimizationResult.init)
        if results != updatedResults { results = updatedResults }
        selection.formIntersection(Set(results.map(\.id)))
        controller.setSelectedObjects(jobs.filter { selection.contains($0.filePath) })
        controller.updateStoppableState()
        isBusy = controller.isBusy
        canStop = controller.isStoppable
        canRevert = controller.canRevert
        canOptimizeAgain = controller.canStartAgainOptimized(false)
        canOptimizeSmaller = controller.canStartAgainOptimized(true)
        canClearCompleted = controller.canClearComplete
        let completed = results.filter { $0.isDone && !$0.isFailed && $0.originalSize > 0 && $0.optimizedSize > 0 }
        originalBytes = completed.reduce(0) { $0 + $1.originalSize }
        bytesSaved = completed.reduce(0) { $0 + max(0, $1.originalSize - $1.optimizedSize) }
    }

    func add(_ urls: [URL]) {
        guard let controller = delegate?.filesController else { return }
        controller.setRow(-1)
        if !controller.add(urls) {
            errorMessage = "Some files could not be opened"
        }
        refresh()
    }

    func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls): add(urls)
        case .failure(let error): errorMessage = error.localizedDescription
        }
    }

    func stop() {
        refresh()
        delegate?.filesController.stopSelected()
        refresh()
    }

    func optimizeAgain(optimizedOnly: Bool = false) {
        refresh()
        delegate?.filesController.startAgainOptimized(optimizedOnly)
        refresh()
    }

    func revert() {
        refresh()
        delegate?.filesController.revert()
        refresh()
    }

    func clearCompleted() {
        delegate?.filesController.clearComplete()
        refresh()
    }

    func removeSelected() {
        guard let controller = delegate?.filesController else { return }
        let jobs = controller.arrangedObjects
        controller.remove(contentsOf: jobs.filter { selection.contains($0.filePath) })
        refresh()
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
        refresh()
        delegate?.copySelectedFiles()
    }

    func copyDataURLs() {
        refresh()
        delegate?.copySelectedDataURLs()
    }

    func pasteFiles() {
        delegate?.pasteFiles()
        refresh()
    }

    func checkForUpdates() {
        delegate?.checkForUpdates()
    }
}
