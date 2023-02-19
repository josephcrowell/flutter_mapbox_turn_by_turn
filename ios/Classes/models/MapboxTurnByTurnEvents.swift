import Foundation

enum MapboxEventType: Int, Codable {
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
