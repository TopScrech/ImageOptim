import ScrechKit

struct QualitySettingsView: View {
    @AppStorage("LossyEnabled") private var lossyEnabled = false
    @AppStorage("JpegOptimMaxQuality") private var jpegQuality = 80.0
    @AppStorage("PngMinQuality") private var pngQuality = 80.0
    @AppStorage("GifQuality") private var gifQuality = 80.0
    @AppStorage("JpegOptimEnabled") private var jpegEnabled = true
    @AppStorage("GifsicleEnabled") private var gifEnabled = true
    @AppStorage("GuetzliEnabled") private var guetzliEnabled = false

    var body: some View {
        Form {
            Toggle(isOn: $lossyEnabled) {
                Text("Enable lossy minification")
                Text("Makes files much smaller, but may change how images look")
            }

            Section("Quality") {
                Slider(value: $jpegQuality, in: (guetzliEnabled ? 85 : 50)...100, step: 1) {
                    Text("JPEG quality: \(jpegQuality.formatted(.number.precision(.fractionLength(0))))%")
                }
                .disabled(!jpegEnabled)

                Slider(value: $pngQuality, in: 40...100, step: 1) {
                    Text("PNG quality: \(pngQuality.formatted(.number.precision(.fractionLength(0))))%")
                }

                Slider(value: $gifQuality, in: 40...100, step: 1) {
                    Text("GIF quality: \(gifQuality.formatted(.number.precision(.fractionLength(0))))%")
                }
                .disabled(!gifEnabled)
            }
            .disabled(!lossyEnabled)
        }
        .formStyle(.grouped)
    }
}
