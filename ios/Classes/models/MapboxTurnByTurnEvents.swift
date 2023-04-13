import Flutter
import Foundation
import os.log

enum MapboxEventType: Int, Codable {
extension OSLog {
  private static var subsystem = Bundle.main.bundleIdentifier!

  /// Logs the view cycles like viewDidLoad.
  static let MapboxTurnByTurnEvents = OSLog(
    subsystem: subsystem, category: "MapboxTurnByTurnEvents")
}

  case progressChange
  case enhancedLocationChange
  case locationChange
  case routeBuilding
  case routeBuilt
  case routeBuildFailed
  case routeBuildCancelled
  case routeBuildNoRoutesFound
  case userOffRoute
  case milestoneEvent
  case muteChanged
  case navigationRunning
  case navigationCancelled
  case navigationCameraChanged
  case fasterRouteFound
  case waypointArrival
  case nextRouteLegStart
  case finalDestinationArrival
  case failedToReroute
  case rerouteAlong
  case stylePackProgress
  case stylePackFinished
  case stylePackError
  case tileRegionProgress
  case tileRegionFinished
  case tileRegionRemoved
  case tileRegionGeometryChanged
  case tileRegionMetadataChanged
  case tileRegionError
}

public class MapboxTurnByTurnEvent : Codable
{
    let eventType: MapboxEventType
    let data: String

    init(eventType: MapboxEventType, data: String) {
        self.eventType = eventType
        self.data = data
    }
}

class MapboxTurnByTurnEvents {
  var eventSink: FlutterEventSink?
  
  init(eventSink: FlutterEventSink?) {
    self.eventSink = eventSink
  }
  
  func sendEvent(eventType: MapboxEventType, data: String = "")
  {
      let turnByTurnEvent = MapboxTurnByTurnEvent(eventType: eventType, data: data)

      let jsonEncoder = JSONEncoder()
      let jsonData = try! jsonEncoder.encode(turnByTurnEvent)
      let eventJson = String(data: jsonData, encoding: String.Encoding.utf8)
      eventSink!(eventJson)
  }
}
