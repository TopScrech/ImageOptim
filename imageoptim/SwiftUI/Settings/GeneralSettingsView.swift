import ScrechKit

struct GeneralSettingsView: View {
    @Environment(SettingsVM.self) private var model
    @AppStorage("PreservePermissions") private var preservePermissions = true
    @AppStorage("PreserveDates") private var preserveDates = false
    @AppStorage("BounceDock") private var bounceDock = true
    @AppStorage("AlwaysOnTop") private var alwaysOnTop = false
    @AppStorage("RunLowPriority") private var runLowPriority = false
    @AppStorage("JpegTranStripAll") private var stripJPEG = true
    @AppStorage("PngOutRemoveChunks") private var stripPNG = true
    @AppStorage("AdvPngLevel") private var optimizationLevel = 4.0

    var body: some View {
        Form {
            Section("Window") {
                Toggle("Always keep window on top", isOn: $alwaysOnTop)
            }

            Section("Files") {
                Toggle("Preserve file permissions", isOn: $preservePermissions)
                Toggle("Preserve modification dates", isOn: $preserveDates)
                Toggle("Strip JPEG metadata", isOn: $stripJPEG)
                Toggle("Strip PNG metadata", isOn: $stripPNG)
            }

            Section("Optimization") {
                Slider(value: $optimizationLevel, in: 1...4, step: 1) {
                    Text("Optimization level")
                }

                Toggle(isOn: $runLowPriority) {
                    Text("Run at low priority")
                    Text("Priority changes take effect after restarting ImageOptim")
                }

                Toggle("Bounce Dock icon when finished", isOn: $bounceDock)
            }
        }
        .formStyle(.grouped)
        .onChange(of: stripJPEG) {
            model.updateJPEGMetadata(isStripped: stripJPEG)
        }
    }
}
