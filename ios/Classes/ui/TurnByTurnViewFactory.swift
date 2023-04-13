import Flutter
import UIKit
import os.log

extension OSLog {
  private static var subsystem = Bundle.main.bundleIdentifier!

  /// Logs the view cycles like viewDidLoad.
  static let TurnByTurnViewFactory = OSLog(subsystem: subsystem, category: "TurnByTurnViewFactory")
}

class TurnByTurnViewFactory: NSObject, FlutterPlatformViewFactory {
  private var messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    os_log("Creating view factory", log: OSLog.TurnByTurnViewFactory, type: .debug)
    return TurnByTurnView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      binaryMessenger: messenger)
  }

  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
