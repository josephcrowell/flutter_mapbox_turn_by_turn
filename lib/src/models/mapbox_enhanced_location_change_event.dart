import 'dart:convert';

import 'package:flutter_mapbox_turn_by_turn/src/utilities.dart';

///This class contains the location at any given time during a navigation session.
///This location includes latitude and longitude.
///With every new valid location update, a new location update event be generated using the latest information.
class MapboxEnhancedLocationChangeEvent {
  bool? isEnhancedLocationChangeEvent;
  double? latitude;
  double? longitude;

  MapboxEnhancedLocationChangeEvent({
    this.isEnhancedLocationChangeEvent,
    this.latitude,
    this.longitude,
  });

  MapboxEnhancedLocationChangeEvent.fromJson(Map<String, dynamic> body) {
    isEnhancedLocationChangeEvent =
        body['isEnhancedLocationChangeEvent'] == true;
    latitude = isNullOrZero(body['latitude']) ? 0.0 : body["latitude"] + .0;
    longitude = isNullOrZero(body['longitude']) ? 0.0 : body["longitude"] + .0;
  }

  MapboxEnhancedLocationChangeEvent.fromString(String jsonString) {
    Map<String, dynamic> body = json.decode(jsonString);
    isEnhancedLocationChangeEvent =
        body['isEnhancedLocationChangeEvent'] == true;
    latitude = isNullOrZero(body['latitude']) ? 0.0 : body["latitude"] + .0;
    longitude = isNullOrZero(body['longitude']) ? 0.0 : body["longitude"] + .0;
  }
}
