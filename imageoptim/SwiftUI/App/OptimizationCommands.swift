import SwiftUI

struct OptimizationCommands: Commands {
    @FocusedValue(\.optimizationModel) private var focusedModel

    var body: some Commands {
        if let model = focusedModel {
            CommandGroup(after: .newItem) {
                Button("Add images", systemImage: "plus") {
                    model.isImporting = true
                }
                .keyboardShortcut("o")
            }

            CommandGroup(replacing: .pasteboard) {
                Button("Copy", systemImage: "doc.on.doc", action: model.copyFiles)
                    .keyboardShortcut("c")
                    .disabled(model.selection.isEmpty)

                Button("Copy as Data URL", systemImage: "link", action: model.copyDataURLs)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .disabled(model.selection.isEmpty)

                Button("Paste", systemImage: "doc.on.clipboard", action: model.pasteFiles)
                    .keyboardShortcut("v")
            }

            CommandMenu("Optimize") {
                Button("Stop", systemImage: "stop", action: model.stop)
                    .keyboardShortcut("s")
                    .disabled(!model.canStop)

                Button("Optimize again", systemImage: "arrow.clockwise") {
                    model.optimizeAgain()
                }
                .keyboardShortcut("r")
                .disabled(!model.canOptimizeAgain)

                Button("Optimize again with smaller files", systemImage: "arrow.clockwise") {
                    model.optimizeAgain(optimizedOnly: true)
                }
                .disabled(!model.canOptimizeSmaller)

                Button("Restore original", systemImage: "arrow.uturn.backward", action: model.revert)
                    .disabled(!model.canRevert)

                Button("Clear completed", systemImage: "trash", action: model.clearCompleted)
                    .keyboardShortcut("k")
                    .disabled(!model.canClearCompleted)

                Divider()

                Button("Quick Look", systemImage: "eye", action: model.preview)
                    .keyboardShortcut("y")
                    .disabled(model.selection.isEmpty)

                Button("Reveal in Finder", systemImage: "folder", action: model.reveal)
                    .disabled(model.selection.isEmpty)
            }

            CommandGroup(replacing: .help) {
                if let url = URL(string: "https://imageoptim.com/mac") {
                    Link("ImageOptim Help", destination: url)
                }
                if let url = URL(string: "https://github.com/ImageOptim/ImageOptim") {
                    Link("Source code", destination: url)
                }
                if let url = URL(string: "https://imageoptim.com/donate.html") {
                    Link("Donate", destination: url)
                }
            }
        }
    }
}
