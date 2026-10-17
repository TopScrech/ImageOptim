import Foundation
import Testing
@testable import ImageOptimImport

struct DirectoryScannerTests {
    @Test func recursivelyImportedMatchingFiles() async throws {
        let root = URL.temporaryDirectory.resolvingSymlinksInPath().appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let nested = root.appending(path: "nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let expected = [root.appending(path: "photo.PNG"), nested.appending(path: "photo.jpeg")]
        for url in expected + [root.appending(path: "notes.txt")] { try Data().write(to: url) }
        try FileManager.default.createDirectory(at: root.appending(path: "folder.png"), withIntermediateDirectories: true)
        var actual: [URL] = []
        for await batch in DirectoryScanner.files(in: root, extensions: ["png", "jpeg"]) {
            actual.append(contentsOf: batch)
        }
        #expect(Set(actual.map { $0.resolvingSymlinksInPath() }) == Set(expected.map { $0.resolvingSymlinksInPath() }))
    }

    @Test func importedAllFilesAcrossBatches() async throws {
        let root = URL.temporaryDirectory.resolvingSymlinksInPath().appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let expected = (0..<400).map { root.appending(path: "image-\($0).png") }
        for url in expected { try Data().write(to: url) }
        var actual: [URL] = []
        var batches = 0
        for await batch in DirectoryScanner.files(in: root, extensions: ["png"]) {
            actual.append(contentsOf: batch)
            batches += 1
        }
        #expect(batches > 1)
        #expect(actual.count == expected.count)
        #expect(Set(actual.map { $0.resolvingSymlinksInPath() }) == Set(expected.map { $0.resolvingSymlinksInPath() }))
    }

    @Test func missingDirectoryFinishedWithoutFiles() async {
        let root = URL.temporaryDirectory.resolvingSymlinksInPath().appending(path: UUID().uuidString)
        var count = 0
        for await batch in DirectoryScanner.files(in: root, extensions: ["png"]) { count += batch.count }
        #expect(count == 0)
    }
}
