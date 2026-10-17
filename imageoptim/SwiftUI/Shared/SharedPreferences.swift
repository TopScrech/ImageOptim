import Foundation

final class SharedPreferences: NSObject {
    static let shared = SharedPreferences()
    let defaults = UserDefaults(suiteName: "59KZTZA4XR.net.pornel.ImageOptim")
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
