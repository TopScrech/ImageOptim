import SwiftUI

@objc(ExtensionController)
final class ExtensionController: NSViewController {
    private let model = ExtensionViewModel()

    override func loadView() {
        model.context = extensionContext
        view = NSHostingView(rootView: ExtensionStatusView().environment(model))
        model.start()
    }
}
