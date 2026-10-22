import SwiftUI

struct WindowLevelView: NSViewRepresentable {
    var alwaysOnTop: Bool

    func makeNSView(context: Context) -> WindowLevelHostView {
        let view = WindowLevelHostView()
        view.alwaysOnTop = alwaysOnTop
        return view
    }

    func updateNSView(_ nsView: WindowLevelHostView, context: Context) {
        nsView.alwaysOnTop = alwaysOnTop
    }
}
