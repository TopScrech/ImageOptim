import SwiftUI

final class ImageOptimController: NSObject, NSApplicationDelegate {
    static weak var current: ImageOptimController?
    let filesController = FilesController()
    private let commandLinePaths: [String]

    override init() {
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
        commandLinePaths = arguments.contains { $0.hasPrefix("-") } ? [] : arguments
        super.init()
        Self.current = self
        registerDefaults()
        filesController.configure()
        filesController.onQueueFinished = { [weak self] in self?.queueFinished() }
    }

    private func registerDefaults() {
        var defaults: [String: Any] = [:]
        if let url = Bundle.main.url(forResource: "defaults", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            defaults = values
        }
        let cpus = ProcessInfo.processInfo.activeProcessorCount
        defaults["RunConcurrentFiles"] = cpus
        defaults["RunConcurrentDirscans"] = Int((Double(cpus) / 3.9).rounded(.up))
        if cpus <= 4 { defaults["PngOutEnabled"] = false }
        if cpus <= 2 { defaults["PngCrush2Enabled"] = false }
        UserDefaults.standard.register(defaults: defaults)
        SharedPreferences.shared.synchronize()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
        if !commandLinePaths.isEmpty { NSApp.hide(self) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !commandLinePaths.isEmpty {
            NSApp.hide(self)
            filesController.addPaths(commandLinePaths)
            if filesController.queueCount == 0 { queueFinished() }
        }
    }

    private func queueFinished() {
        guard !filesController.isBusy else { return }
        if !commandLinePaths.isEmpty {
            NSApp.terminate(self)
        } else if UserDefaults.standard.bool(forKey: "BounceDock") {
            NSApp.requestUserAttention(.informationalRequest)
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        sender.reply(toOpenOrPrint: filesController.addPaths(filenames) ? .success : .failure)
    }

    @objc func handleServices(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        filesController.add(readFileURLs(from: pasteboard))
    }

    func revealURLs(_ urls: [URL]) {
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func copySelectedFiles() {
        let urls = filesController.selectedObjects.map(\.filePath)
        guard !urls.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(urls as [NSURL])
    }

    func copySelectedDataURLs() {
        var urls: [String] = []
        var totalSize: UInt = 0
        for job in filesController.selectedObjects where job.isDone {
            guard let file = job.savedOutputOrInput, file.byteSize <= 100_000 else { continue }
            totalSize += file.byteSize
            guard totalSize <= 1_000_000 else { break }
            if let data = try? Data(contentsOf: file.path) {
                urls.append("data:\(file.mimeType);base64,\(data.base64EncodedString())")
            }
        }
        guard !urls.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(urls.joined(separator: "\n"), forType: .string)
    }

    func pasteFiles() {
        filesController.add(readFileURLs(from: .general))
    }

    private func readFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        filesController.cleanup()
    }
}
