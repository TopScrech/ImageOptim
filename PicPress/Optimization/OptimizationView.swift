import ScrechKit
import UniformTypeIdentifiers
import QuickLook

struct OptimizationView: View {
    @Environment(OptimizationVM.self) private var vm
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        @Bindable var vm = vm

        VStack {
            if vm.results.isEmpty {
                ContentUnavailableView {
                    Label("Drop images here", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("Optimize PNG, JPEG, GIF, and SVG images or add a folder")
                } actions: {
                    Button("Add images", systemImage: "plus") {
                        vm.isImporting = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                OptimizationTableView()

                Divider()

                OptimizationStatusView()
                    .padding([.horizontal, .bottom])
            }
        }
        .frame(minWidth: 650, minHeight: 300)
        .toolbar {
            OptimizationToolbar()
        }
        .fileImporter(isPresented: $vm.isImporting,
                      allowedContentTypes: [.png, .jpeg, .gif, .svg, .folder],
                      allowsMultipleSelection: true,
                      onCompletion: vm.importFiles)
        .dropDestination(for: URL.self) { urls, _ in
            vm.add(urls)
            return !urls.isEmpty
        }
        .quickLookPreview($vm.previewURL)
        .alert("Could not add images", isPresented: $vm.showsError) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear {
            vm.setUndoManager(undoManager)
        }
    }
}
