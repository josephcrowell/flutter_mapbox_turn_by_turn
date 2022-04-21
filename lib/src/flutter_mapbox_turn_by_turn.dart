import 'dart:async';

import 'package:flutter/services.dart';

class FlutterMapboxTurnByTurn {
  static const MethodChannel _channel =
      MethodChannel('flutter_mapbox_turn_by_turn/method');

  static Future<bool> hasPermission() async {
    final bool? result = await _channel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }
}
