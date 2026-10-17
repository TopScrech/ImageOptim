import ScrechKit

struct OptimizationStatusView: View {
    @Environment(OptimizationViewModel.self) private var model
    @AppStorage("LossyEnabled") private var lossyEnabled = false
    @AppStorage("GuetzliEnabled") private var guetzliEnabled = false

    var body: some View {
        HStack {
            if model.isBusy {
                ProgressView()
                    .controlSize(.small)

                Text("Optimizing images")
            } else if model.originalBytes > 0 {
                Text("Saved \(model.bytesSaved.formatted(.byteCount(style: .file))) out of \(model.originalBytes.formatted(.byteCount(style: .file)))")
                    .enableSelection()
            } else {
                Text("Images are optimized in place")
            }

            Spacer()

            if guetzliEnabled {
                Label("Guetzli can be very slow", systemImage: "exclamationmark.triangle")
            } else if lossyEnabled {
                Text("Lossy minification enabled")
            }
        }
        .callout()
        .secondary()
    }
}
