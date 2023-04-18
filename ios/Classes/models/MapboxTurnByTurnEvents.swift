import Flutter
import Foundation
import os.log

extension OSLog {
  private static var subsystem = Bundle.main.bundleIdentifier!

  /// Logs the view cycles like viewDidLoad.
  static let MapboxTurnByTurnEvents = OSLog(
    subsystem: subsystem, category: "MapboxTurnByTurnEvents")
}

enum MapboxEventType: String, Codable {
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

public class MapboxTurnByTurnEvent: Codable {
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
  
  func sendEvent(event: MapboxProgressChangeEvent) {
    let jsonData = try! JSONEncoder().encode(event)

    let jsonString =
      "{ \"eventType\": \"\(MapboxEventType.progressChange)\"," + " \"data\": \(jsonData)}"
    eventSink!(jsonString)
  }
  
  func sendEvent(event: MapboxEnhancedLocationChangeEvent) {
    let jsonString =
      "{ \"eventType\": \"\(MapboxEventType.enhancedLocationChange)\"," + " \"data\": {"
      + "\"isEnhancedLocationChangeEvent\": \(event.isEnhancedLocationChangeEvent),"
    + "\"latitude\": \(event.latitude ?? 0)," + "\"longitude\": \(event.longitude ?? 0)" + "}}"
    eventSink!(jsonString)
  }

  func sendEvent(event: MapboxLocationChangeEvent) {
    let jsonString =
      "{ \"eventType\": \"\(MapboxEventType.locationChange)\"," + " \"data\": {"
      + "\"isEnhancedLocationChangeEvent\": \(event.isLocationChangeEvent),"
      + "\"latitude\": \(event.latitude ?? 0)," + "\"longitude\": \(event.longitude ?? 0)" + "}}"
    eventSink!(jsonString)
  }
  
  func sendEvent(eventType: MapboxEventType, data: String = "") {
    do {
      let turnByTurnEvent = MapboxTurnByTurnEvent(eventType: eventType, data: data)

      let jsonData = try JSONEncoder().encode(turnByTurnEvent)
      let eventJson = String(data: jsonData, encoding: String.Encoding.utf8)
      os_log("JSON data: %{public}@", log: OSLog.MapboxTurnByTurnEvents, type: .info, eventJson!)
      eventSink!(eventJson)
    } catch {
      os_log("Could not create event JSON data", log: OSLog.MapboxTurnByTurnEvents, type: .error)
    }
  }
  
  func sendJsonEvent(eventType: MapboxEventType, data: String = "") {
    var dataString = "\"\""
    
    if !data.isEmpty {
      dataString = data
    }
    
    let jsonString = "{ \"eventType\": \"\(eventType)\"," +
      " \"data\": " + dataString + "}"
    eventSink!(jsonString)
  }
}
