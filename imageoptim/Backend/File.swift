import Foundation

public nonisolated struct File: Sendable {
    public let path: URL
    public let byteSize: UInt
    public let fileType: FileType

    public init?(data: Data, fromPath path: URL) {
        guard data.count >= 6 else { return nil }
        if data.starts(with: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a]) {
            fileType = .png
        } else if data.starts(with: [0xff, 0xd8, 0xff]) {
            fileType = .jpeg
        } else if data.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            fileType = .gif
        } else if data.starts(with: Array("<svg".utf8)) || path.pathExtension.lowercased() == "svg" {
            fileType = .svg
        } else {
            return nil
        }
        self.path = path
        byteSize = UInt(data.count)
    }

    init(path: URL, byteSize: UInt, fileType: FileType) {
        self.path = path
        self.byteSize = byteSize
        self.fileType = fileType
    }

    func at(_ path: URL) -> File {
        File(path: path, byteSize: byteSize, fileType: fileType)
    }

    public var isLarge: Bool { byteSize > (fileType == .png ? 250 * 1024 : 1024 * 1024) }
    public var isSmall: Bool { byteSize < (fileType == .png ? 2048 : 10 * 1024) }
    public var mimeType: String? {
        switch fileType {
        case .png: "image/png"
        case .jpeg: "image/jpeg"
        case .gif: "image/gif"
        case .svg: "image/svg+xml"
        }
    }
}
