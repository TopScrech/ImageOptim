import SwiftUI

struct OptimizationTableView: View {
    @Environment(OptimizationViewModel.self) private var model
    @State private var sortOrder = [KeyPathComparator(\OptimizationResult.name)]

    var body: some View {
        @Bindable var model = model

        Table(model.results.sorted(using: sortOrder), selection: $model.selection, sortOrder: $sortOrder) {
            TableColumn("File", value: \.name) {
                OptimizationFileView(result: $0)
            }

            TableColumn("Original", value: \.originalSize) {
                Text($0.originalSize, format: .byteCount(style: .file))
                    .monospacedDigit()
            }

            TableColumn("Optimized", value: \.optimizedSize) {
                Text($0.optimizedSize, format: .byteCount(style: .file))
                    .monospacedDigit()
            }

            TableColumn("Savings", value: \.savings) {
                Text($0.savings, format: .percent.precision(.fractionLength(1)))
                    .monospacedDigit()
            }

            TableColumn("Tool", value: \.tool)
        }
        .contextMenu {
            Button("Quick Look", systemImage: "eye", action: model.preview)
                .disabled(model.selection.isEmpty)

            Button("Reveal in Finder", systemImage: "folder", action: model.reveal)
                .disabled(model.selection.isEmpty)

            Button("Restore original", systemImage: "arrow.uturn.backward", action: model.revert)
                .disabled(!model.canRevert)

            Button("Remove", systemImage: "trash", action: model.removeSelected)
                .disabled(model.selection.isEmpty)
        }
        .onDeleteCommand(perform: model.removeSelected)
    }
}
