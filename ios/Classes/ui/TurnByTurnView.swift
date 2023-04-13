import CoreLocation
import Flutter
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import UIKit
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
    static let TurnByTurnView = OSLog(subsystem: subsystem, category: "TurnByTurnView")
}

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
    
    os_log("View initialized", log: OSLog.TurnByTurnView, type: .debug)
  }
  
  func view() -> UIView {
    return nativeView.view
  }
}
