import 'dart:convert';

import 'package:flutter_mapbox_turn_by_turn/src/models/mapbox_enhanced_location_change_event.dart';
import 'package:flutter_mapbox_turn_by_turn/src/models/mapbox_location_change_event.dart';
import 'package:flutter_mapbox_turn_by_turn/src/models/mapbox_progress_change_event.dart';

enum MapboxEventType {
  progressChange,
  enhancedLocationChange,
  locationChange,
  routeBuilding,
  routeBuilt,
  routeBuildFailed,
  routeBuildCancelled,
  routeBuildNoRoutesFound,
  userOffRoute,
  milestoneEvent,
  muteChanged,
  navigationRunning,
  navigationCancelled,
  navigationCameraChanged,
  fasterRouteFound,
  waypointArrival,
  nextRouteLegStart,
  finalDestinationArrival,
  failedToReroute,
  rerouteAlong,
  stylePackProgress,
  stylePackFinished,
  stylePackError,
  tileRegionProgress,
  tileRegionFinished,
  tileRegionRemoved,
  tileRegionGeometryChanged,
  tileRegionMetadataChanged,
  tileRegionError,
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
      case MapboxEventType.enhancedLocationChange:
        data = MapboxEnhancedLocationChangeEvent.fromJson(dataJson);
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
