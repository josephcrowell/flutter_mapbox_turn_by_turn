import Flutter
import UIKit

public class SwiftFlutterMapboxTurnByTurnPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_mapbox_turn_by_turn/method", binaryMessenger: registrar.messenger())
    let factory = TurnByTurnViewFactory(messenger: registrar.messenger())
    let instance = SwiftFlutterMapboxTurnByTurnPlugin()
    registrar.register(factory, withId: "MapView")
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? NSDictionary

    if(call.method == "hasPermission")
    {
      hasPermission(result: result)
    }
    else
    {
      result("Method \(call.method) is Not Implemented");
    }
  }

  func hasPermission(result: FlutterResult?)
  {
    result!(true)
  }
}
