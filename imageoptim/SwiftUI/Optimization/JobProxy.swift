import SwiftUI

@Observable
final class JobProxy {
    let job: Job
    private(set) var isDone = false
    private(set) var isFailed = false
    private(set) var isBusy = false
    private(set) var isOptimized = false
    private(set) var canRevert = false
    private(set) var isStoppable = false
    private(set) var byteSizeOriginal: Int64?
    private(set) var byteSizeOptimized: Int64?
    private(set) var bestToolName: String?
    private(set) var statusText: String?
    private var observations: [NSKeyValueObservation] = []

    init(job: Job) {
        self.job = job
        observe(\.isDone, snapshot: { $0 }) { $0.isDone = $1 }
        observe(\.isFailed, snapshot: { $0 }) { $0.isFailed = $1 }
        observe(\.isBusy, snapshot: { $0 }) { $0.isBusy = $1 }
        observe(\.byteSizeOriginal, snapshot: { $0?.int64Value }) { $0.byteSizeOriginal = $1 }
        observe(\.byteSizeOptimized, snapshot: { $0?.int64Value }) { $0.byteSizeOptimized = $1 }
        observe(\.bestToolName, snapshot: { $0 }) { $0.bestToolName = $1 }
        observe(\.statusText, snapshot: { $0 }) { $0.statusText = $1 }
        updateActions()
    }

    private func observe<Value, Snapshot: Sendable>(
        _ keyPath: KeyPath<Job, Value>,
        snapshot: @escaping @Sendable (Value) -> Snapshot,
        update: @escaping @MainActor (JobProxy, Snapshot) -> Void
    ) {
        update(self, snapshot(job[keyPath: keyPath]))
        observations.append(job.observe(keyPath, options: [.new]) { [weak self] _, change in
            guard let value = change.newValue else { return }
            let valueSnapshot = snapshot(value)
            Task { @MainActor [weak self] in
                guard let self else { return }
                update(self, valueSnapshot)
                self.updateActions()
            }
        })
    }

    var filePath: URL { job.filePath }
    var displayName: String { job.displayName }
    var savedOutputOrInput: File? { job.savedOutput ?? job.unoptimizedInput }

    private func updateActions() {
        isOptimized = job.isOptimized
        canRevert = job.canRevert
        isStoppable = job.isStoppable
    }

    @discardableResult
    func stop() -> Bool { job.stop() }

    @discardableResult
    func revert() -> Bool { job.revert() }
}
