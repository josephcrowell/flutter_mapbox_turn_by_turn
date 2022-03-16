
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterMapboxTurnByTurn {
  static const MethodChannel _channel = MethodChannel('flutter_mapbox_turn_by_turn');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
