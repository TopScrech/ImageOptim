import Foundation

final class SharedPreferences: NSObject {
    static let shared = SharedPreferences()
    let defaults = (Bundle.main.object(forInfoDictionaryKey: "PicPressAppGroup") as? String)
        .flatMap { $0.isEmpty ? nil : UserDefaults(suiteName: $0) }
    private static let keys = [
        "AdvPngEnabled", "AdvPngLevel", "GifsicleEnabled", "JpegOptimEnabled",
        "JpegTranEnabled", "JpegTranStripAll", "OptiPngEnabled", "PngCrush2Enabled",
        "PngOutEnabled", "PngOutRemoveChunks", "ZopfliEnabled", "PngMinQuality",
        "JpegOptimMaxQuality", "GifQuality", "LossyEnabled", "GuetzliEnabled",
        "SvgcleanerEnabled", "SvgoEnabled"
    ]
    private var isObserving = false

    func synchronize() {
        guard defaults != nil else { return }
        copyDefaults()
        guard !isObserving else { return }
        isObserving = true
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged),
                                               name: UserDefaults.didChangeNotification, object: UserDefaults.standard)
    }

    @objc nonisolated private func defaultsChanged(_ notification: Notification) {
        Task { @MainActor [weak self] in self?.copyDefaults() }
    }

    private func copyDefaults() {
        guard let defaults else { return }
        for key in Self.keys {
            if let value = UserDefaults.standard.object(forKey: key) {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
