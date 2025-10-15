import AVFAudio
import HaishinKit
import Logboard
import RTMPHaishinKit
import SRTHaishinKit
import UIKit

let logger = LBLogger.with("com.haishinkit.Exsample.tvOS")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Task {
            await SessionBuilderFactory.shared.register(RTMPSessionFactory())
            await SessionBuilderFactory.shared.register(SRTSessionFactory())
        }
        return true
    }
}
