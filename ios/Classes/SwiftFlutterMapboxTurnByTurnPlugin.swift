import Flutter
import Foundation
import UIKit
import CoreLocation
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
    static let TurnByTurnPlugin = OSLog(subsystem: subsystem, category: "TurnByTurnPlugin")
}

public class SwiftFlutterMapboxTurnByTurnPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private let operationQueue = OperationQueue()

    override init() {
        super.init()

        // Pause the operation queue because
        // we don't know if we have location permissions yet
        operationQueue.isSuspended = true
        locationManager.delegate = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
      os_log("Registering view factory", log: OSLog.TurnByTurnPlugin, type: .debug)
      let channel =
          FlutterMethodChannel(
              name: "flutter_mapbox_turn_by_turn/method",
              binaryMessenger: registrar.messenger()
          )
      let instance = SwiftFlutterMapboxTurnByTurnPlugin()
      let factory = TurnByTurnViewFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "MapView")
      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary

        if call.method == "hasPermission" {
            hasPermission(result: result)
        } else {
            result("Method \(call.method) is Not Implemented")
        }
    }

    func hasPermission(result: FlutterResult?) {
        let locStatus = CLLocationManager.authorizationStatus()
        switch locStatus {
        case .notDetermined:
            runLocationCheck {
                let newStatus = CLLocationManager.authorizationStatus()
                switch newStatus {
                case .authorizedAlways, .authorizedWhenInUse:
                    result!(true)
                default:
                    result!(false)
                }
            }
        case .denied, .restricted:
            result!(false)
        case .authorizedAlways, .authorizedWhenInUse:
            result!(true)
        }
    }

    /// When the user presses the allow/don't allow buttons on the popup dialogue
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        // If we're authorized to use location services, run all operations in the queue
        // otherwise if we were denied access, cancel the operations
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.operationQueue.isSuspended = false
        } else if status == .denied {
            self.operationQueue.cancelAllOperations()
        }
    }

    /// Checks the status of the location permission
    /// and adds the callback block to the queue to run when finished checking
    /// NOTE: Anything done in the UI should be enclosed in `DispatchQueue.main.async {}`
    func runLocationCheck(callback: @escaping () -> Void) {

        // Get the current authorization status
        let authState = CLLocationManager.authorizationStatus()

        // If we have permissions, start executing the commands immediately
        // otherwise request permission
        if authState == .authorizedAlways || authState == .authorizedWhenInUse {
            self.operationQueue.isSuspended = false
        } else {
            // Request permission
            locationManager.requestAlwaysAuthorization()
        }

        // Create a closure with the callback function so we can add it to the operationQueue
        let block = { callback() }

        // Add block to the queue to be executed asynchronously
        self.operationQueue.addOperation(block)
    }
}
