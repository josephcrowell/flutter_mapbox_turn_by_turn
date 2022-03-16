import Flutter
import UIKit

public class SwiftFlutterMapboxTurnByTurnPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_mapbox_turn_by_turn", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMapboxTurnByTurnPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
