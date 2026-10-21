import ScrechKit

struct OptimizationStatusView: View {
    @Environment(OptimizationVM.self) private var vm
    
    @AppStorage("LossyEnabled") private var lossyEnabled = false
    @AppStorage("GuetzliEnabled") private var guetzliEnabled = false

    var body: some View {
        HStack {
            if vm.isBusy {
                ProgressView()
                    .controlSize(.small)

                Text("Optimizing images")
            } else if vm.originalBytes > 0 {
                Text("Saved \(vm.bytesSaved.formatted(.byteCount(style: .file))) out of \(vm.originalBytes.formatted(.byteCount(style: .file)))")
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
