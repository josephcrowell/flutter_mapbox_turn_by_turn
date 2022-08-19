import 'dart:convert';

import 'mapbox_progress_change_event.dart';
import 'mapbox_location_change_event.dart';

enum MapboxEventType {
  progressChange,
  locationChange,
  routeBuilding,
  routeBuilt,
  routeBuildFailed,
  routeBuildCancelled,
  routeBuildNoRoutesFound,
  userOffRoute,
  milestoneEvent,
  navigationRunning,
  navigationCancelled,
  fasterRouteFound,
  waypointArrival,
  nextRouteLegStart,
  finalDestinationArrival,
  failedToReroute,
  rerouteAlong,
  offlineProgress,
  offlineFinished,
  offlineRegionRemoved,
  offlineRegionGeometryChanged,
  offlineRegionMetadataChanged,
  offlineError,
}

/// Represents an event sent by the navigation service
class MapboxTurnByTurnEvent {
  MapboxEventType? eventType;
  dynamic data;

  MapboxTurnByTurnEvent({this.eventType, this.data});

  MapboxTurnByTurnEvent.fromJson(Map<String, dynamic> json) {
    if (json['eventType'] is int) {
      eventType = MapboxEventType.values[json['eventType']];
    } else {
      try {
        eventType = MapboxEventType.values.firstWhere(
            (e) => e.toString().split(".").last == json['eventType']);
      } on StateError {
        //When the list is empty or eventType not found (Bad State: No Element)
      }
    }
    var dataJson = json['data'];
    switch (eventType) {
      case MapboxEventType.progressChange:
        data = MapboxProgressChangeEvent.fromJson(dataJson);
        break;
      case MapboxEventType.locationChange:
        data = MapboxLocationChangeEvent.fromJson(dataJson);
        break;
      default:
        data = jsonEncode(json['data']);
        break;
    }
  }
}
