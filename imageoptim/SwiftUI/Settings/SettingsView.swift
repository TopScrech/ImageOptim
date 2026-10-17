import ScrechKit

struct SettingsView: View {
    @State private var model = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }

            QualitySettingsView()
                .tabItem { Label("Quality", systemImage: "slider.horizontal.3") }

            ToolSettingsView()
                .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver") }
        }
        .environment(model)
        .frame(width: 520, height: 560)
    }
}
