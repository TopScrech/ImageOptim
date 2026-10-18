import Foundation
import Testing

@MainActor
final class BackendTests {
    @Test func compressOne() throws {
        let originalURL = try #require(Bundle(for: Self.self).url(forResource: "unoptimized", withExtension: "png"))
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appending(path: "image.png")
        try FileManager.default.copyItem(at: originalURL, to: fileURL)
        let originalData = try Data(contentsOf: originalURL)

        let suiteName = "ImageOptim.BackendTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "OptiPngEnabled")
        defaults.set(true, forKey: "PngOutRemoveChunks")
        defaults.set(2, forKey: "AdvPngLevel")
        defaults.set(false, forKey: "LossyEnabled")
        for key in ["PngCrush2Enabled", "PngOutEnabled", "ZopfliEnabled", "AdvPngEnabled"] {
            defaults.set(false, forKey: key)
        }

        let job = try #require(Job(filePath: fileURL, resultsDatabase: nil))
        defer { job.cleanup() }
        let queue = try #require(JobQueue(cpus: 4, dirs: 1, files: 4, defaults: defaults))
        defer { queue.cleanup() }
        queue.add(job)
        #expect(job.isBusy)
        #expect(!job.isDone)
        #expect(!job.isFailed)
        queue.wait()

        let optimizedData = try Data(contentsOf: fileURL)
        #expect(!job.isBusy)
        #expect(job.isDone)
        #expect(!job.isFailed)
        #expect(!job.isStoppable)
        #expect(!optimizedData.isEmpty)
        #expect(optimizedData.count < originalData.count)
        #expect(job.byteSizeOptimized?.intValue == optimizedData.count)
        #expect(job.byteSizeOriginal?.intValue == originalData.count)
        #expect(job.canRevert)
        #expect(job.revert())
        #expect(try Data(contentsOf: fileURL) == originalData)
    }
}
