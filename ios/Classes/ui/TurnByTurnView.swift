import CoreLocation
import Flutter
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import UIKit

class TurnByTurnView: NSObject, FlutterPlatformView {
  let viewId: Int64
  private var nativeView: TurnByTurnNative

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?
  ) {
    self.viewId = viewId

    nativeView = TurnByTurnNative.init(frame: frame, arguments: args, binaryMessenger: messenger)

    super.init()
  }

  func view() -> UIView {
      return nativeView.view
  }
}
