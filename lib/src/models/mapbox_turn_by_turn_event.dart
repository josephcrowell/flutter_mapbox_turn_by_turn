import 'dart:convert';
import 'package:flutter/scheduler.dart';

import 'mapbox_progress_change_event.dart';
import 'mapbox_location_change_event.dart';

enum MapboxEventType {
  progressChange,
  locationChange,
  mapReady,
  routeBuilding,
  routeBuilt,
  routeBuildFailed,
  routeBuildCancelled,
  routeBuildNoRoutesFound,
  userOffRoute,
  milestoneEvent,
  navigationRunning,
  navigationCancelled,
  navigationFinished,
  fasterRouteFound,
  speechAnnouncement,
  bannerInstruction,
  onArrival,
  failedToReroute,
  rerouteAlong,
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
      } catch (e) {}
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
