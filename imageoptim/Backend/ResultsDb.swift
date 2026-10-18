import Foundation
import SQLite3

@MainActor
public final class ResultsDb {
    private var database: OpaquePointer?

    public init?() {
        let directory = URL.cachesDirectory.appending(path: Bundle.main.bundleIdentifier ?? "ImageOptim", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch { return nil }
        guard sqlite3_open(directory.appending(path: "SwiftResults.db").path, &database) == SQLITE_OK else {
            sqlite3_close(database)
            database = nil
            return nil
        }
        guard sqlite3_exec(database, "CREATE TABLE IF NOT EXISTS results (hash TEXT PRIMARY KEY)", nil, nil, nil) == SQLITE_OK else {
            sqlite3_close(database)
            database = nil
            return nil
        }
    }

    isolated deinit { sqlite3_close(database) }

    func contains(_ hash: String) -> Bool {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(database, "SELECT 1 FROM results WHERE hash = ?", -1, &statement, nil) == SQLITE_OK else { return false }
        return hash.withCString {
            sqlite3_bind_text(statement, 1, $0, -1, nil)
            return sqlite3_step(statement) == SQLITE_ROW
        }
    }

    func insert(_ hash: String) {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(database, "INSERT OR IGNORE INTO results VALUES (?)", -1, &statement, nil) == SQLITE_OK else { return }
        hash.withCString {
            sqlite3_bind_text(statement, 1, $0, -1, nil)
            _ = sqlite3_step(statement)
        }
    }
}
