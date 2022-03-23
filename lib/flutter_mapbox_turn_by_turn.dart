import 'dart:async';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapboxTurnByTurn {
  static const MethodChannel _channel =
      MethodChannel('flutter_mapbox_turn_by_turn/method');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> startNavigation({required List<LatLng> waypoints}) async {
    await _channel.invokeMethod('startNavigation', {'waypoints': waypoints});
  }
}
