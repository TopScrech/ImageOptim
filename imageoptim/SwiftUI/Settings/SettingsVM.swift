import SwiftUI

@Observable
final class SettingsVM {
    var showsGuetzliWarning = false
    let supportsSVGO = FileManager.default.isExecutableFile(atPath: "/usr/local/bin/node")
        || FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/node")

    func resetTools() {
        updateGuetzli(isEnabled: false)
        showsGuetzliWarning = false

        let toolKeys = [
            "JpegOptimEnabled", "JpegTranEnabled", "GuetzliEnabled",
            "OptiPngEnabled", "AdvPngEnabled", "PngCrush2Enabled",
            "PngOutEnabled", "ZopfliEnabled", "GifsicleEnabled",
            "SvgcleanerEnabled", "SvgoEnabled"
        ]

        for key in toolKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func updateGuetzli(isEnabled: Bool) {
        let defaults = UserDefaults.standard
        if isEnabled {
            showsGuetzliWarning = true
            if defaults.double(forKey: "JpegOptimMaxQuality") < 85 {
                defaults.set(85, forKey: "JpegOptimMaxQuality")
            }
            if !defaults.bool(forKey: "JpegTranStripAll") {
                defaults.set(true, forKey: "JpegTranStripAllSetByGuetzli")
                defaults.set(true, forKey: "JpegTranStripAll")
            }
        } else if defaults.bool(forKey: "JpegTranStripAllSetByGuetzli") {
            defaults.set(false, forKey: "JpegTranStripAllSetByGuetzli")
            defaults.set(false, forKey: "JpegTranStripAll")
        }
    }

    func updateJPEGMetadata(isStripped: Bool) {
        if !isStripped {
            UserDefaults.standard.set(false, forKey: "GuetzliEnabled")
            UserDefaults.standard.set(false, forKey: "JpegTranStripAllSetByGuetzli")
        }
    }
}
