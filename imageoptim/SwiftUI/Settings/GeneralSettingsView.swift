import ScrechKit

struct GeneralSettingsView: View {
    @Environment(SettingsViewModel.self) private var model
    @AppStorage("PreservePermissions") private var preservePermissions = true
    @AppStorage("PreserveDates") private var preserveDates = false
    @AppStorage("BounceDock") private var bounceDock = true
    @AppStorage("RunLowPriority") private var runLowPriority = false
    @AppStorage("JpegTranStripAll") private var stripJPEG = true
    @AppStorage("PngOutRemoveChunks") private var stripPNG = true
    @AppStorage("AdvPngLevel") private var optimizationLevel = 4.0

    var body: some View {
        Form {
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

                Toggle("Run at low priority", isOn: $runLowPriority)
                Text("Priority changes take effect after restarting ImageOptim")
                    .caption()
                    .secondary()

                Toggle("Bounce Dock icon when finished", isOn: $bounceDock)
            }
        }
        .formStyle(.grouped)
        .onChange(of: stripJPEG) {
            model.updateJPEGMetadata(isStripped: stripJPEG)
        }
    }
}
