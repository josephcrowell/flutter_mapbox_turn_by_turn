import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_mapbox_turn_by_turn/src/models/point.dart';

class FlutterMapboxTurnByTurn {
  static const MethodChannel _channel =
      MethodChannel('flutter_mapbox_turn_by_turn/method');

  static Future<bool> hasPermission() async {
    final bool? result = await _channel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }

  static Future<void> startNavigation(
      {required List<Point> destinations}) async {
    await _channel
        .invokeMethod('startNavigation', {'destinations': destinations});
  }
}
