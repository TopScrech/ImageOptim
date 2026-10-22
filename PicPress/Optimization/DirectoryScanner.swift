import Foundation

nonisolated struct DirectoryScanner {
    static func files(in directory: URL, extensions: Set<String>) -> AsyncStream<[URL]> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            let task = Task.detached(priority: .userInitiated) {
                defer { continuation.finish() }
                guard let enumerator = FileManager.default.enumerator(
                    at: directory,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [],
                    errorHandler: { _, _ in true }
                ) else { return }
                var buffer: [URL] = []
                var batchSize = 16
                while let url = enumerator.nextObject() as? URL {
                    guard !Task.isCancelled else { return }
                    guard extensions.contains(url.pathExtension.lowercased()),
                          (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
                    buffer.append(url)
                    if buffer.count >= batchSize {
                        continuation.yield(buffer)
                        buffer.removeAll(keepingCapacity: true)
                        batchSize = min(256, batchSize * 4)
                    }
                }
                if !buffer.isEmpty { continuation.yield(buffer) }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
