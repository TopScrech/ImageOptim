import Foundation
import CryptoKit

nonisolated enum FileOperations {
    @concurrent static func read(_ path: URL) async throws -> File {
        let data = try Data(contentsOf: path)
        guard let file = File(data: data, fromPath: path) else { throw CocoaError(.fileReadCorruptFile) }
        return file
    }

    @concurrent static func hash(_ path: URL, settings: String) async throws -> String {
        fingerprint(try Data(contentsOf: path), settings: settings)
    }

    static func fingerprint(_ data: Data, settings: String) -> String {
        var hash = SHA256()
        hash.update(data: Data(settings.utf8))
        hash.update(data: data)
        return hash.finalize().map { String(256 + Int($0), radix: 16).dropFirst() }.joined()
    }

    @concurrent static func copy(_ source: URL, to destination: URL) async throws {
        try FileManager.default.copyItem(at: source, to: destination)
    }

    @concurrent static func remove(_ directory: URL) async {
        try? FileManager.default.removeItem(at: directory)
    }

    @concurrent static func save(_ output: File, over input: File, settings: OptimizationSettings, expectedHash: String) async throws -> URL {
        let manager = FileManager.default
        let originalData = try Data(contentsOf: input.path)
        guard fingerprint(originalData, settings: settings.cacheIdentifier) == expectedHash else { throw CocoaError(.fileWriteFileExists) }
        let data = try Data(contentsOf: output.path)
        guard data.count == output.byteSize, !data.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        let attributes = try manager.attributesOfItem(atPath: input.path.path)
        // Keep a recovery copy beside the original until replacement has succeeded
        let backup = input.path.deletingLastPathComponent().appending(path: ".\(UUID().uuidString).imageoptim-backup")
        try manager.copyItem(at: input.path, to: backup)
        do {
            if settings.preservePermissions {
                let handle = try FileHandle(forWritingTo: input.path)
                defer { try? handle.close() }
                try handle.write(contentsOf: data)
                try handle.truncate(atOffset: UInt64(data.count))
                try handle.synchronize()
            } else {
                try data.write(to: input.path, options: .atomic)
            }
            if settings.preserveDates {
                let dates = attributes.filter { $0.key == .creationDate || $0.key == .modificationDate }
                try manager.setAttributes(dates, ofItemAtPath: input.path.path)
            }
        } catch {
            // Leave the backup recoverable if restoring the destination also fails
            _ = try? manager.replaceItemAt(input.path, withItemAt: backup)
            throw error
        }
        for attribute in ["com.apple.FinderInfo", "com.apple.ResourceFork", "com.apple.quarantine", "com.apple.metadata:kMDItemWhereFroms"] {
            _ = input.path.path.withCString { path in attribute.withCString { removexattr(path, $0, 0) } }
        }
        var trashed: NSURL?
        do {
            try manager.trashItem(at: backup, resultingItemURL: &trashed)
            return trashed as URL? ?? backup
        } catch {
            return backup
        }
    }
}
