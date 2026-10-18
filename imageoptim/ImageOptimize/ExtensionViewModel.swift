import ImageOptimGPL
import SwiftUI
import UniformTypeIdentifiers

@Observable
final class ExtensionViewModel {
    var status = String(localized: "Optimizing image")
    @ObservationIgnored weak var context: NSExtensionContext?
    private var task: Task<Void, Never>?
    private var currentFile: Job?
    private var queue: JobQueue?
    private var temporaryURL: URL?
    private var hasFinished = false

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in await self?.optimize() }
    }

    private func optimize() async {
        guard let item = context?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first,
              provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            cancel()
            return
        }
        do {
            let data = try await loadImage(from: provider)
            try Task.checkCancellation()
            let url = URL.temporaryDirectory.appending(path: UUID().uuidString)
            temporaryURL = url
            try data.write(to: url)
            let job = Job(filePath: url, resultsDatabase: nil)
            currentFile = job
            let defaults = SharedPreferences.shared.defaults ?? .standard
            defaults.register(defaults: [
                "AdvPngEnabled": true, "AdvPngLevel": 4, "ZopfliEnabled": true,
                "PngOutRemoveChunks": true, "PreservePermissions": false,
                "PreserveDates": false, "RunLowPriority": false,
                "JpegTranEnabled": true, "JpegTranStripAll": true,
                "GifsicleEnabled": true, "PngMinQuality": 70,
                "JpegOptimMaxQuality": 80, "LossyEnabled": true
            ])
            let queue = JobQueue(cpus: 0, files: 1, defaults: defaults)
            self.queue = queue
            queue.add(job)
            while queue.queueCount() > 0 {
                try await Task.sleep(for: .milliseconds(100))
            }
            try Task.checkCancellation()
            let optimized = job.isOptimized
            status = optimized
                ? String(localized: "Optimized with \(job.bestToolName ?? "ImageOptim")")
                : String(localized: "Already optimized")
            currentFile = nil
            try await Task.sleep(for: .seconds(1))
            guard optimized, let result = NSItemProvider(contentsOf: url), let context else {
                cancel()
                return
            }
            item.attachments = [result]
            hasFinished = true
            await complete(context, returning: item)
            cleanup()
        } catch {
            cancel()
        }
    }

    private func loadImage(from provider: NSItemProvider) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? CocoaError(.fileReadUnknown))
                }
            }
        }
    }

    private func complete(_ context: NSExtensionContext, returning item: NSExtensionItem) async {
        await withCheckedContinuation { continuation in
            context.completeRequest(returningItems: [item]) { _ in
                continuation.resume()
            }
        }
    }

    func stop() {
        if let currentFile, currentFile.isStoppable, currentFile.isBusy {
            _ = currentFile.stop()
        } else {
            cancel()
        }
    }

    private func cancel() {
        guard !hasFinished else { return }
        hasFinished = true
        task?.cancel()
        if let currentFile { _ = currentFile.stop() }
        queue?.cleanup()
        context?.cancelRequest(withError: CocoaError(.userCancelled))
        Task {
            while (queue?.queueCount() ?? 0) > 0 {
                try? await Task.sleep(for: .milliseconds(100))
            }
            cleanup()
        }
    }

    private func cleanup() {
        if let temporaryURL { try? FileManager.default.removeItem(at: temporaryURL) }
        temporaryURL = nil
        currentFile = nil
    }
}
