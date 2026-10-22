import ScrechKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model = SettingsVM()

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            QualitySettingsView()
                .tabItem {
                    Label("Quality", systemImage: "slider.horizontal.3")
                }

            ToolSettingsView()
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver")
                }
        }
        .environment(model)
        .focusedSceneValue(\.closeSettings, dismiss)
        .onExitCommand {
            dismiss()
        }
        .frame(width: 520, height: 560)
    }
}
