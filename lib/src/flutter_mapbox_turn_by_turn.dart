import 'dart:async';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapboxTurnByTurn {
  static const MethodChannel _channel =
      MethodChannel('flutter_mapbox_turn_by_turn/method');

  static Future<int?> get sdkVersion async {
    final int? version = await _channel.invokeMethod('getSdkVersion');
    return version;
  }

  static Future<bool> hasPermission() async {
    final bool? result = await _channel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }

  /*static Future<void> startNavigation({required List<LatLng> waypoints}) async {
    await _channel.invokeMethod('startNavigation', {'waypoints': waypoints});
  }*/
}
