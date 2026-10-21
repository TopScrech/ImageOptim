import SwiftUI

final class WindowLevelHostView: NSView {
    var alwaysOnTop = false {
        didSet {
            updateWindowLevel()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateWindowLevel()
    }

    private func updateWindowLevel() {
        window?.level = alwaysOnTop ? .floating : .normal
    }
}
