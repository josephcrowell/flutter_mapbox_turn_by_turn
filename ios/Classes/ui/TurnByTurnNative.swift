import Flutter
import UIKit
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

public class TurnByTurnNative : NSObject, FlutterStreamHandler
{
    let messenger: FlutterBinaryMessenger
    let methodChannel: FlutterMethodChannel
    let eventChannel: FlutterEventChannel
}
