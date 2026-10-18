@testable import ImageOptimGPL
import Foundation
import Testing
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class BackendTests {
    @Test(arguments: [false, true]) func compressOne(preserveMetadata: Bool) async throws {
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
        defaults.set(preserveMetadata, forKey: "PreservePermissions")
        defaults.set(preserveMetadata, forKey: "PreserveDates")
        let originalDate = Date(timeIntervalSince1970: 1_600_000_000)
        try FileManager.default.setAttributes([.modificationDate: originalDate, .posixPermissions: 0o640], ofItemAtPath: fileURL.path)
        defaults.set(true, forKey: "OptiPngEnabled")
        defaults.set(true, forKey: "PngOutRemoveChunks")
        defaults.set(2, forKey: "AdvPngLevel")
        defaults.set(false, forKey: "LossyEnabled")
        for key in ["PngCrush2Enabled", "PngOutEnabled", "ZopfliEnabled", "AdvPngEnabled"] {
            defaults.set(false, forKey: key)
        }

        let job = Job(filePath: fileURL, resultsDatabase: nil)
        defer { job.cleanup() }
        let queue = JobQueue(cpus: 4, files: 4, defaults: defaults)
        defer { queue.cleanup() }
        queue.add(job)
        #expect(job.isBusy)
        #expect(!job.isDone)
        #expect(!job.isFailed)
        await queue.wait()

        let optimizedData = try Data(contentsOf: fileURL)
        #expect(!job.isBusy)
        #expect(job.isDone)
        #expect(!job.isFailed)
        #expect(!job.isStoppable)
        #expect(!optimizedData.isEmpty)
        #expect(optimizedData.count < originalData.count)
        #expect(job.byteSizeOptimized == Int64(optimizedData.count))
        #expect(job.byteSizeOriginal == Int64(originalData.count))
        if preserveMetadata {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            #expect(attributes[.modificationDate] as? Date == originalDate)
            #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o640)
        }
        #expect(job.canRevert)
        #expect(job.revert())
        #expect(try Data(contentsOf: fileURL) == originalData)
    }

    @Test func rejectedUnsupportedFile() async throws {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("not an image".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let job = Job(filePath: url, resultsDatabase: nil)
        let queue = JobQueue(cpus: 1, files: 1, defaults: .standard)
        queue.add(job)
        await queue.wait()
        #expect(job.isFailed)
        #expect(job.isDone)
        #expect(!job.isBusy)
        #expect(queue.queueCount() == 0)
        #expect(try String(contentsOf: url, encoding: .utf8) == "not an image")
    }

    @Test func cancelledQueuedJobFinishes() async throws {
        let job = Job(filePath: URL(filePath: "/nonexistent.png"), resultsDatabase: nil)
        let queue = JobQueue(cpus: 1, files: 1, defaults: .standard)
        queue.add(job)
        #expect(job.stop())
        await queue.wait()
        #expect(job.isDone)
        #expect(!job.isFailed)
        #expect(!job.isBusy)
        #expect(queue.queueCount() == 0)
    }

    @Test func cancelledProcessExits() async throws {
        let runner = CommandWorker()
        let task = Task {
            try await runner.run(executable: URL(filePath: "/bin/sleep"), arguments: ["30"], lowPriority: false)
        }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        let status = try await task.value
        #expect(status != 0)
    }

    @Test func sameSizeExternalEditIsPreserved() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let inputURL = directory.appending(path: "input.svg")
        let outputURL = directory.appending(path: "output.svg")
        try Data("<svg>original</svg>".utf8).write(to: inputURL)
        try Data("<svg/>".utf8).write(to: outputURL)
        let input = try await FileOperations.read(inputURL)
        let output = try await FileOperations.read(outputURL)
        let settings = OptimizationSettings(defaults: .standard)
        let hash = try await FileOperations.hash(inputURL, settings: settings.cacheIdentifier)
        try Data("<svg>modified</svg>".utf8).write(to: inputURL)
        do {
            _ = try await FileOperations.save(output, over: input, settings: settings, expectedHash: hash)
            Issue.record("Saving should reject an externally edited original")
        } catch {
            #expect(try String(contentsOf: inputURL, encoding: .utf8) == "<svg>modified</svg>")
        }
    }
    @Test(arguments: ["advpng", "oxipng", "pngcrush", "pngout", "pngquant", "zopflipng", "jpegoptim", "jpegtran", "guetzli", "gifsicle", "svgo", "svgcleaner"])
    func optimizerSmokeTest(executable: String) async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fixture = try #require(Bundle(for: Self.self).url(forResource: "unoptimized", withExtension: "png"))
        let svg = ["svgo", "svgcleaner"].contains(executable)
        let jpeg = ["jpegoptim", "jpegtran", "guetzli"].contains(executable)
        let gif = executable == "gifsicle"
        let type: UTType = jpeg ? .jpeg : (gif ? .gif : .png)
        let input = directory.appending(path: svg ? "input.svg" : "input.image")
        let output = directory.appending(path: svg ? "output.svg" : "output.image")
        if svg {
            try Data("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\"><rect x=\"0\" y=\"0\" width=\"100\" height=\"100\" fill=\"#ff0000\"/></svg>".utf8).write(to: input)
        } else if jpeg || gif {
            let source = try #require(CGImageSourceCreateWithURL(fixture as CFURL, nil))
            let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
            let destination = try #require(CGImageDestinationCreateWithURL(input as CFURL, type.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            #expect(CGImageDestinationFinalize(destination))
        } else {
            try FileManager.default.copyItem(at: fixture, to: input)
        }
        let file = try await FileOperations.read(input)
        let suite = "ImageOptim.WorkerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "PngOutRemoveChunks")
        defaults.set(true, forKey: "JpegTranStripAll")
        defaults.set(2, forKey: "AdvPngLevel")
        let optimizer = Optimizer(executable, name: executable, quality: executable == "guetzli" ? 84 : 80)
        let result = try await optimizer.optimize(file, output: output, settings: OptimizationSettings(defaults: defaults), repeated: false, runner: CommandWorker())
        if let result {
            #expect(result.byteSize < file.byteSize)
            #expect(result.fileType == file.fileType)
            if !svg {
                let source = try #require(CGImageSourceCreateWithURL(result.path as CFURL, nil))
                #expect(CGImageSourceCreateImageAtIndex(source, 0, nil) != nil)
            }
        }
        #expect(try Data(contentsOf: input).count == file.byteSize)
    }

}
