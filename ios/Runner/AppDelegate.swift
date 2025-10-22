import FirebaseCore
import Flutter
import UIKit
import Foundation

private enum ChannelName {
  static let deviceTimezone = "receitagora/device_timezone"
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
         let options = FirebaseOptions(contentsOfFile: filePath) {
        FirebaseApp.configure(options: options)
      } else {
        NSLog("Firebase setup skipped: GoogleService-Info.plist missing from bundle")
      }
    }
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: ChannelName.deviceTimezone,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getLocalTimezone":
          result(TimeZone.current.identifier)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
