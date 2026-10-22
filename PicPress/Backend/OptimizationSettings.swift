import Foundation

nonisolated struct OptimizationSettings: Sendable {
    let enabled: Set<String>
    let level: Int
    let lossy: Bool
    let pngQuality: Int
    let jpegQuality: Int
    let gifQuality: Int
    let stripPNG: Bool
    let stripJPEG: Bool
    let preservePermissions: Bool
    let preserveDates: Bool
    let lowPriority: Bool

    init(defaults: UserDefaults) {
        enabled = Set(["PngCrush2", "OptiPng", "PngOut", "Zopfli", "AdvPng", "Guetzli", "JpegOptim", "JpegTran", "Gifsicle", "Svgo", "Svgcleaner"].filter { defaults.bool(forKey: $0 + "Enabled") })
        level = max(0, defaults.integer(forKey: "AdvPngLevel"))
        lossy = defaults.bool(forKey: "LossyEnabled")
        pngQuality = defaults.integer(forKey: "PngMinQuality")
        jpegQuality = defaults.integer(forKey: "JpegOptimMaxQuality")
        gifQuality = defaults.integer(forKey: "GifQuality")
        stripPNG = defaults.bool(forKey: "PngOutRemoveChunks")
        stripJPEG = defaults.bool(forKey: "JpegTranStripAll")
        preservePermissions = defaults.bool(forKey: "PreservePermissions")
        preserveDates = defaults.bool(forKey: "PreserveDates")
        lowPriority = defaults.bool(forKey: "RunLowPriority")
    }

    var cacheIdentifier: String {
        "swift-1|\(enabled.sorted())|\(level)|\(lossy)|\(pngQuality)|\(jpegQuality)|\(gifQuality)|\(stripPNG)|\(stripJPEG)"
    }
}
