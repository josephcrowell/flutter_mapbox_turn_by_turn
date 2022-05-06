import 'dart:convert';

import 'package:flutter_mapbox_turn_by_turn/src/utilities.dart';

///This class contains the location at any given time during a navigation session.
///This location includes latitude and longitude.
///With every new valid location update, a new location update event be generated using the latest information.
class MapboxLocationChangeEvent {
  bool? isLocationChangeEvent;
  double? latitude;
  double? longitude;

  MapboxLocationChangeEvent({
    this.isLocationChangeEvent,
    this.latitude,
    this.longitude,
  });

  MapboxLocationChangeEvent.fromJson(Map<String, dynamic> body) {
    isLocationChangeEvent = body['isLocationChangeEvent'] == true;
    latitude = isNullOrZero(body['latitude']) ? 0.0 : body["latitude"] + .0;
    longitude = isNullOrZero(body['longitude']) ? 0.0 : body["longitude"] + .0;
  }

  MapboxLocationChangeEvent.fromString(String jsonString) {
    Map<String, dynamic> body = json.decode(jsonString);
    isLocationChangeEvent = body['isLocationChangeEvent'] == true;
    latitude = isNullOrZero(body['latitude']) ? 0.0 : body["latitude"] + .0;
    longitude = isNullOrZero(body['longitude']) ? 0.0 : body["longitude"] + .0;
  }
}
