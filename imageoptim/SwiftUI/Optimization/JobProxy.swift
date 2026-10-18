import SwiftUI
import ImageOptimGPL

@Observable
final class JobProxy {
    let job: Job

    init(job: Job) { self.job = job }

    var isDone: Bool { job.isDone }
    var isFailed: Bool { job.isFailed }
    var isBusy: Bool { job.isBusy }
    var isOptimized: Bool { job.isOptimized }
    var canRevert: Bool { job.canRevert }
    var isStoppable: Bool { job.isStoppable }
    var byteSizeOriginal: Int64? { job.byteSizeOriginal }
    var byteSizeOptimized: Int64? { job.byteSizeOptimized }
    var bestToolName: String? { job.bestToolName }
    var statusText: String? { job.statusText }
    var filePath: URL { job.filePath }
    var displayName: String { job.displayName }
    var savedOutputOrInput: File? { job.savedOutput ?? job.unoptimizedInput }

    @discardableResult
    func stop() -> Bool { job.stop() }

    @discardableResult
    func revert() -> Bool { job.revert() }
}
