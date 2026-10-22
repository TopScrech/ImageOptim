import SwiftUI

nonisolated struct OptimizationResult: Identifiable, Equatable, Sendable {
    let id: URL
    let name: String
    let originalSize: Int64
    let optimizedSize: Int64
    let savings: Double
    let tool: String
    let status: String
    let isBusy: Bool
    let isFailed: Bool
    let isDone: Bool

    @MainActor
    init(_ job: JobProxy) {
        id = job.filePath
        name = job.displayName
        originalSize = job.byteSizeOriginal ?? 0
        optimizedSize = job.byteSizeOptimized ?? 0
        savings = originalSize > 0 && optimizedSize > 0
            ? 1 - Double(optimizedSize) / Double(originalSize) : 0
        tool = job.bestToolName ?? ""
        status = job.statusText ?? ""
        isBusy = job.isBusy
        isFailed = job.isFailed
        isDone = job.isDone
    }
}
