import ScrechKit

struct ExtensionStatusView: View {
    @Environment(ExtensionVM.self) private var vm

    var body: some View {
        VStack {
            ProgressView()

            Text(vm.status)
                .secondary()

            Button("Stop", systemImage: "stop", action: vm.stop)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 150)
    }
}
