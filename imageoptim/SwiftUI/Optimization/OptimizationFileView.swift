import SwiftUI

struct OptimizationFileView: View {
    let result: OptimizationResult

    var body: some View {
        HStack {
            if result.isBusy {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: result.isFailed ? "exclamationmark.triangle" : result.isDone ? "checkmark.circle" : "photo")
                    .foregroundStyle(result.isFailed ? .red : result.isDone ? .green : .secondary)
            }

            Text(result.name)
                .lineLimit(1)
        }
        .help(result.status.isEmpty ? result.id.path : result.status)
        .draggable(result.id)
    }
}
