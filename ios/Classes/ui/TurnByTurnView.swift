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
  private var failView: UIView

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?
  ) {
    failView = UIView()
    self.viewId = viewId
    
    nativeView = TurnByTurnNative.init(frame: frame, arguments: args, binaryMessenger: messenger)
    
    super.init()

    createFailView()
  }

  func view() -> UIView {
    if nativeView.navigationMapView != nil {
      return nativeView.view
    }

    return failView
  }

  func createFailView() {
    failView.backgroundColor = UIColor.purple
    let nativeLabel = UILabel()
    nativeLabel.text = "Map not initialized"
    nativeLabel.textColor = UIColor.white
    nativeLabel.textAlignment = .center
    nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
    failView.addSubview(nativeLabel)
  }
}
