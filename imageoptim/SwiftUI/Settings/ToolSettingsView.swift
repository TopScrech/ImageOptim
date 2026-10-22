import ScrechKit

struct ToolSettingsView: View {
    @Environment(SettingsVM.self) private var vm
    
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
        @Bindable var vm = vm

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
                .disabled(!vm.supportsSVGO)
            }

            Section {
                Button("Reset to Defaults", systemImage: "arrow.counterclockwise", action: vm.resetTools)
            }
        }
        .formStyle(.grouped)
        .onChange(of: guetzli) {
            vm.updateGuetzli(isEnabled: guetzli)
        }
        .alert("Guetzli is very slow", isPresented: $vm.showsGuetzliWarning) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("It can take up to 30 minutes per image and may make your system unresponsive")
        }
    }
}
