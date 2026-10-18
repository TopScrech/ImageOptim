import ScrechKit

struct ToolSettingsView: View {
    @Environment(SettingsViewModel.self) private var model
    @AppStorage("JpegOptimEnabled") private var jpegOptim = true
    @AppStorage("JpegTranEnabled") private var jpegTran = true
    @AppStorage("GuetzliEnabled") private var guetzli = false
    @AppStorage("OptiPngEnabled") private var oxiPNG = true
    @AppStorage("AdvPngEnabled") private var advPNG = true
    @AppStorage("PngCrush2Enabled") private var pngCrush = false
    @AppStorage("PngOutEnabled") private var pngOut = true
    @AppStorage("ZopfliEnabled") private var zopfli = true
    @AppStorage("GifsicleEnabled") private var gifsicle = true
    @AppStorage("SvgcleanerEnabled") private var svgcleaner = true
    @AppStorage("SvgoEnabled") private var svgo = false

    var body: some View {
        @Bindable var model = model

        Form {
            Section("JPEG") {
                Toggle("JPEGOptim", isOn: $jpegOptim)
                Toggle("Jpegtran", isOn: $jpegTran)
                Toggle("Guetzli", isOn: $guetzli)
            }

            Section("PNG") {
                Toggle("OxiPNG", isOn: $oxiPNG)
                Toggle("AdvPNG", isOn: $advPNG)
                Toggle("PNGCrush", isOn: $pngCrush)
                Toggle("PNGOUT", isOn: $pngOut)
                Toggle("Zopfli", isOn: $zopfli)
            }

            Section("GIF and SVG") {
                Toggle("Gifsicle", isOn: $gifsicle)
                Toggle("svgcleaner", isOn: $svgcleaner)
                
                Toggle(isOn: $svgo) {
                    Text("SVGO")
                    Text("SVGO requires Node.js installed in /usr/local/bin or /opt/homebrew/bin")
                }
                .disabled(!model.supportsSVGO)
            }
        }
        .formStyle(.grouped)
        .onChange(of: guetzli) {
            model.updateGuetzli(isEnabled: guetzli)
        }
        .alert("Guetzli is very slow", isPresented: $model.showsGuetzliWarning) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("It can take up to 30 minutes per image and may make your system unresponsive")
        }
    }
}
