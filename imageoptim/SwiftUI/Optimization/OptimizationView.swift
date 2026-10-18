import ScrechKit
import UniformTypeIdentifiers
import QuickLook

struct OptimizationView: View {
    @Environment(OptimizationViewModel.self) private var model
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        @Bindable var model = model

        VStack {
            if model.results.isEmpty {
                ContentUnavailableView {
                    Label("Drop images here", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("Optimize PNG, JPEG, GIF, and SVG images or add a folder")
                } actions: {
                    Button("Add images", systemImage: "plus") {
                        model.isImporting = true
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
        .fileImporter(isPresented: $model.isImporting,
                      allowedContentTypes: [.png, .jpeg, .gif, .svg, .folder],
                      allowsMultipleSelection: true,
                      onCompletion: model.importFiles)
        .dropDestination(for: URL.self) { urls, _ in
            model.add(urls)
            return !urls.isEmpty
        }
        .quickLookPreview($model.previewURL)
        .alert("Could not add images", isPresented: $model.showsError) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear {
            model.setUndoManager(undoManager)
        }
    }
}
