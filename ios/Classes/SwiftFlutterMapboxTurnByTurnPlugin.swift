import Flutter
import UIKit

public class SwiftFlutterMapboxTurnByTurnPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = TurnByTurnViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "MapView")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
