import ScrechKit

struct ExtensionStatusView: View {
    @Environment(ExtensionViewModel.self) private var model

    var body: some View {
        VStack {
            ProgressView()

            Text(model.status)
                .secondary()

            Button("Stop", systemImage: "stop", action: model.stop)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 150)
    }
}
