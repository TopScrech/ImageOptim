import SwiftUI

@objc(GetQueueCountCommand)
nonisolated final class GetQueueCountCommand: NSScriptCommand {
    nonisolated override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { () -> Int in PicPressController.current?.filesController.queueCount ?? 0 }
    }
}
