import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Font detection platform channel
    // Responds to `isNewYorkAvailable` by checking UIFont.familyNames for .NewYorkFont
    let controller = engineBridge.pluginRegistry as! FlutterViewController
    let fontChannel = FlutterMethodChannel(
      name: "com.ontaskhq.ontask/fonts",
      binaryMessenger: controller.binaryMessenger
    )
    fontChannel.setMethodCallHandler { call, result in
      if call.method == "isNewYorkAvailable" {
        let families = UIFont.familyNames
        result(families.contains(".NewYorkFont"))
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
