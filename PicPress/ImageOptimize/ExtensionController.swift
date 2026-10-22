import SwiftUI

@objc(ExtensionController)
final class ExtensionController: NSViewController {
    private let vm = ExtensionVM()

    override func loadView() {
        vm.context = extensionContext
        view = NSHostingView(rootView: ExtensionStatusView().environment(vm))
        vm.start()
    }
}
