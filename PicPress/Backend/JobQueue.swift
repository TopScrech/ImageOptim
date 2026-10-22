import Foundation

@MainActor
@Observable
public final class JobQueue {
    public var onBusyChanged: (() -> Void)?
    private var jobs: [ObjectIdentifier: Job] = [:]
    private let defaults: UserDefaults
    private let cpuLimiter: AsyncLimiter
    private let fileLimiter: AsyncLimiter
    private let guetzliLimiter = AsyncLimiter(limit: 1)

    public init(cpus: Int, files: Int, defaults: UserDefaults) {
        self.defaults = defaults
        cpuLimiter = AsyncLimiter(limit: cpus > 0 ? cpus : ProcessInfo.processInfo.activeProcessorCount)
        fileLimiter = AsyncLimiter(limit: files > 0 ? files : 2)
    }

    public func add(_ job: Job) {
        let id = ObjectIdentifier(job)
        guard jobs[id] == nil, !job.isBusy else { return }
        let settings = OptimizationSettings(defaults: defaults)
        jobs[id] = job
        job.prepare()
        onBusyChanged?()
        job.task = Task(priority: settings.lowPriority ? .utility : .userInitiated) {
            await cpuLimiter.acquire()
            await job.run(settings: settings, fileLimiter: fileLimiter, guetzliLimiter: guetzliLimiter)
            cpuLimiter.release()
            jobs[id] = nil
            onBusyChanged?()
        }
    }

    public func queueCount() -> Int { jobs.count }

    public func wait() async {
        while !jobs.isEmpty {
            let tasks = jobs.values.compactMap(\.task)
            for task in tasks { await task.value }
            if tasks.isEmpty { await Task.yield() }
        }
    }

    public func cleanup() {
        for job in jobs.values { job.cleanup() }
    }
}
