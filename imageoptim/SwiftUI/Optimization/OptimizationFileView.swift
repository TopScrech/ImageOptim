import ScrechKit

struct OptimizationFileView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let result: OptimizationResult

    var body: some View {
        HStack {
            ZStack {
                if result.isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                } else {
                    Image(systemName: result.isFailed ? "exclamationmark.triangle" : result.isDone ? "checkmark" : "photo")
                        .foregroundStyle(result.isFailed ? .red : result.isDone ? .green : .secondary)
                        .contentTransition(reduceMotion ? .opacity : .symbolEffect(.replace))
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .smooth, value: result.isBusy)
            .animation(reduceMotion ? nil : .smooth, value: result.isFailed)
            .animation(reduceMotion ? nil : .smooth, value: result.isDone)

            Text(result.name)
                .lineLimit(1)
        }
        .help(result.status.isEmpty ? result.id.path : result.status)
        .draggable(result.id)
    }
}
