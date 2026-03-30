import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize the Flutter engine first — GeneratedPluginRegistrant and
    // binaryMessenger are only valid after super.application() returns.
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Font detection platform channel.
    // Registered after super.application() so the Flutter engine is fully
    // initialised and binaryMessenger is ready to accept handlers.
    if let controller = window?.rootViewController as? FlutterViewController {
      let fontChannel = FlutterMethodChannel(
        name: "com.ontaskhq.ontask/fonts",
        binaryMessenger: controller.binaryMessenger
      )
      fontChannel.setMethodCallHandler { call, result in
        if call.method == "isNewYorkAvailable" {
          // .NewYorkFont is a private UIFont family available on iOS 13+.
          let families = UIFont.familyNames
          result(families.contains(".NewYorkFont"))
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    // If rootViewController is not a FlutterViewController (e.g. unit tests,
    // scene-based lifecycle), the channel is simply not registered and
    // font_channel.dart falls back to Playfair Display gracefully.

    return result
  }
}
