import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // Font detection platform channel.
    // IMPORTANT: registered before super.application() so the channel is
    // available as soon as Flutter's engine initialises.
    let fontChannel = FlutterMethodChannel(
      name: "com.ontaskhq.ontask/fonts",
      binaryMessenger: controller.binaryMessenger
    )
    fontChannel.setMethodCallHandler { call, result in
      if call.method == "isNewYorkAvailable" {
        // .NewYorkFont is a private UIFont family name that exists on iOS 13+.
        // familyNames returns a sorted list; contains() is O(n) but called
        // once at startup, so performance is not a concern.
        let families = UIFont.familyNames
        result(families.contains(".NewYorkFont"))
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
