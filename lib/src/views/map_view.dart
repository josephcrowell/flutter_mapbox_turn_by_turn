import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_turn_by_turn/src/models/mapbox_progress_change_event.dart';

import 'package:flutter_mapbox_turn_by_turn/src/models/mapbox_turn_by_turn_event.dart';
import 'package:flutter_mapbox_turn_by_turn/src/models/waypoint.dart';
import 'package:flutter_mapbox_turn_by_turn/src/utilities.dart';

int sdkVersion = 0;

class Language {
  /// Arabic
  static const String arabic = "ar";

  /// Chinese
  static const String chinese = "zh";

  /// Simplified Chinese
  static const String chineseSimplified = "zh-CN";

  /// Taiwanese
  static const String chineseTaiwan = "zh-TW";

  /// Danish
  static const String danish = "da";

  /// Dutch
  static const String dutch = "de";

  /// English
  static const String english = "en";

  /// English with Canadian accent
  static const String englishCanada = "en-CA";

  /// English with British accent
  static const String englishUK = "en-GB";

  /// English with US accent
  static const String englishUS = "en-US";

  /// French
  static const String french = "fr";

  /// Canadian French
  static const String frenchCanada = "fr-CA";

  /// German
  static const String german = "de-DE";

  /// Hebrew
  static const String hebrew = "he";

  /// Hungarian
  static const String hungarian = "hu";

  /// Italian
  static const String italian = "it";

  /// Japanese
  static const String japanese = "ja";

  /// Korean
  static const String korean = "ko";

  /// Portuguese
  static const String portuguese = "pt-PT";

  /// Brazilian Portuguese
  static const String portugueseBrazil = "pt-BR";

  /// Russian
  static const String russian = "ru";

  /// Spanish
  static const String spanish = "es-ES";

  /// Spanish with Mexican accent
  static const String spanishMexico = "es";

  /// Swedish
  static const String swedish = "sv";
}

class RouteProfile {
  /// For pedestrian and hiking routing. This profile shows the shortest path by using sidewalks and trails.
  static const String walking = "walking";

  /// For bicycle routing. This profile shows routes that are short and safe for cyclist, avoiding highways and preferring streets with bike lanes.
  static const String cycling = "cycling";

  /// For car and motorcycle routing. This profile shows the fastest routes by preferring high-speed roads like highways.
  static const String driving = "driving";

  /// For car and motorcycle routing. This profile factors in current and historic traffic conditions to avoid slowdowns.
  static const String drivingTraffic = "driving-traffic";
}

/// Metric or Imperial units
class MeasurementUnits {
  /// Use metric units of measurement.
  static const String metric = "metric";

  /// Use imperial units of measurement.
  static const String imperial = "imperial";
}

Stream<MapboxTurnByTurnEvent>? _onMapboxTurnByTurnEvent;

// The widget that show the mapbox MapView
class MapView extends StatelessWidget {
  final MethodChannel _methodChannel =
      const MethodChannel('flutter_mapbox_turn_by_turn/map_view/method');
  final EventChannel _eventChannel =
      const EventChannel('flutter_mapbox_turn_by_turn/map_view/events');

  MapView({
    Key? key,
    this.eventNotifier,
    this.zoom,
    this.pitch,
    this.disableGesturesWhenNavigating,
    this.navigateOnLongClick,
    this.showStopButton,
    this.showSpeedIndicator,
    this.routeProfile,
    this.language,
    this.measurementUnits,
    this.speedThreshold,
    this.showAlternativeRoutes,
    this.allowUTurnsAtWaypoints,
    this.mapStyleUrlDay,
    this.mapStyleUrlNight,
    this.routeCasingColor,
    this.routeDefaultColor,
    this.restrictedRoadColor,
    this.routeLineTraveledColor,
    this.routeLineTraveledCasingColor,
    this.routeClosureColor,
    this.routeLowCongestionColor,
    this.routeModerateCongestionColor,
    this.routeHeavyCongestionColor,
    this.routeSevereCongestionColor,
    this.routeUnknownCongestionColor,
  }) : super(key: key) {
    getSdkVersion();
    _methodChannel.setMethodCallHandler(_handleMethod);
  }

  final ValueSetter<MapboxTurnByTurnEvent>? eventNotifier;
  late final StreamSubscription<MapboxTurnByTurnEvent>?
      _mapboxTurnByTurnEventSubscription;

  getSdkVersion() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      sdkVersion = androidInfo.version.sdkInt!;
    } else {
      sdkVersion = -1;
    }
  }

  final double? zoom;
  final double? pitch;
  final bool? disableGesturesWhenNavigating;
  final bool? navigateOnLongClick;
  final bool? showStopButton;
  final bool? showSpeedIndicator;
  final String? routeProfile;
  final String? language;
  final String? measurementUnits;
  final int? speedThreshold;
  final bool? showAlternativeRoutes;
  final bool? allowUTurnsAtWaypoints;
  final String? mapStyleUrlDay;
  final String? mapStyleUrlNight;
  final Color? routeCasingColor;
  final Color? routeDefaultColor;
  final Color? restrictedRoadColor;
  final Color? routeLineTraveledColor;
  final Color? routeLineTraveledCasingColor;
  final Color? routeClosureColor;
  final Color? routeLowCongestionColor;
  final Color? routeModerateCongestionColor;
  final Color? routeHeavyCongestionColor;
  final Color? routeSevereCongestionColor;
  final Color? routeUnknownCongestionColor;

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'MapView';

    String routeCasingColorString = "#0066ff";
    if (routeCasingColor != null) {
      routeCasingColorString = "#${routeCasingColor?.value.toRadixString(16)}";
    }

    String routeDefaultColorString = "#0066ff";
    if (routeDefaultColor != null) {
      routeDefaultColorString =
          "#${routeDefaultColor?.value.toRadixString(16)}";
    }

    String restrictedRoadColorString = "#737373";
    if (restrictedRoadColor != null) {
      restrictedRoadColorString =
          "#${restrictedRoadColor?.value.toRadixString(16)}";
    }

    String routeLineTraveledColorString = "#b3b3b3";
    if (routeLineTraveledColor != null) {
      routeLineTraveledColorString =
          "#${routeLineTraveledColor?.value.toRadixString(16)}";
    }

    String routeLineTraveledCasingColorString = "#b3b3b3";
    if (routeLineTraveledCasingColor != null) {
      routeLineTraveledCasingColorString =
          "#${routeLineTraveledCasingColor?.value.toRadixString(16)}";
    }

    String routeClosureColorString = "#4a4a4a";
    if (routeClosureColor != null) {
      routeClosureColorString =
          "#${routeClosureColor?.value.toRadixString(16)}";
    }

    String routeLowCongestionColorString = "#0066ff";
    if (routeLowCongestionColor != null) {
      routeLowCongestionColorString =
          "#${routeLowCongestionColor?.value.toRadixString(16)}";
    }

    String routeModerateCongestionColorString = "#ffc400";
    if (routeModerateCongestionColor != null) {
      routeModerateCongestionColorString =
          "#${routeModerateCongestionColor?.value.toRadixString(16)}";
    }

    String routeHeavyCongestionColorString = "#ff8000";
    if (routeHeavyCongestionColor != null) {
      routeHeavyCongestionColorString =
          "#${routeHeavyCongestionColor?.value.toRadixString(16)}";
    }

    String routeSevereCongestionColorString = "#ff0000";
    if (routeSevereCongestionColor != null) {
      routeSevereCongestionColorString =
          "#${routeSevereCongestionColor?.value.toRadixString(16)}";
    }

    String routeUnknownCongestionColorString = "#0066ff";
    if (routeUnknownCongestionColor != null) {
      routeUnknownCongestionColorString =
          "#${routeUnknownCongestionColor?.value.toRadixString(16)}";
    }

    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{
      "zoom": zoom,
      "pitch": pitch,
      "disableGesturesWhenNavigating": disableGesturesWhenNavigating ?? true,
      "navigateOnLongClick": navigateOnLongClick,
      "showStopButton": showStopButton,
      "showSpeedIndicator": showSpeedIndicator ?? true,
      "routeProfile": routeProfile ?? RouteProfile.drivingTraffic,
      "language": language ?? Language.englishUS,
      "measurementUnits": measurementUnits ?? MeasurementUnits.metric,
      "speedThreshold": speedThreshold ?? 5,
      "showAlternativeRoutes": showAlternativeRoutes ?? false,
      "allowUTurnsAtWaypoints": allowUTurnsAtWaypoints ?? false,
      "mapStyleUrlDay": mapStyleUrlDay,
      "mapStyleUrlNight": mapStyleUrlNight,
      "routeCasingColor": routeCasingColorString,
      "routeDefaultColor": routeDefaultColorString,
      "restrictedRoadColor": restrictedRoadColorString,
      "routeLineTraveledColor": routeLineTraveledColorString,
      "routeLineTraveledCasingColor": routeLineTraveledCasingColorString,
      "routeClosureColor": routeClosureColorString,
      "routeLowCongestionColor": routeLowCongestionColorString,
      "routeModerateCongestionColor": routeModerateCongestionColorString,
      "routeHeavyCongestionColor": routeHeavyCongestionColorString,
      "routeSevereCongestionColor": routeSevereCongestionColorString,
      "routeUnknownCongestionColor": routeUnknownCongestionColorString,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (sdkVersion < 29) {
          debugPrint("Android SDK is less than 29. Using virtual display.");
          return AndroidView(
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          );
        }

        debugPrint("Android SDK is greater than 28. Using hybrid composition.");
        return PlatformViewLink(
          viewType: viewType,
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <
                  Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () {
                params.onFocusChanged(true);
              },
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec());
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  /// Generic Handler for Messages sent from the Platform
  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'initializeEventNotifier':
        if (eventNotifier != null) {
          _mapboxTurnByTurnEventSubscription =
              _eventStream!.listen(_onEventData);
          log.d('Event Notifier is initialized');
        } else {
          log.d('Event Notifier is not initialized because it is null');
        }
        break;
    }
  }

  /// Starts the Navigation
  Future<bool?> startNavigation({required List<Waypoint> waypoints}) async {
    assert(waypoints.isNotEmpty);
    List<Map<String, Object?>> waypointList = [];

    for (int i = 0; i < waypoints.length; i++) {
      var waypoint = waypoints[i];

      final pointMap = <String, dynamic>{
        "order": i,
        "name": waypoint.name,
        "latitude": waypoint.latitude,
        "longitude": waypoint.longitude,
      };
      waypointList.add(pointMap);
    }
    var i = 0;
    var waypointMap = {for (var e in waypointList) i++: e};

    var args = <String, dynamic>{};
    args["waypoints"] = waypointMap;
    return _methodChannel.invokeMethod('startNavigation', args);
  }

  Future<bool?> stopNavigation() async {
    return _methodChannel.invokeMethod('stopNavigation');
  }

  void _onEventData(MapboxTurnByTurnEvent event) {
    if (eventNotifier != null) {
      eventNotifier!(event);
    }
  }

  Stream<MapboxTurnByTurnEvent>? get _eventStream {
    _onMapboxTurnByTurnEvent ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => _parseRouteEvent(event));
    return _onMapboxTurnByTurnEvent;
  }

  MapboxTurnByTurnEvent _parseRouteEvent(String jsonString) {
    MapboxTurnByTurnEvent event;
    var map = json.decode(jsonString);
    var progressEvent = MapboxProgressChangeEvent.fromJson(map);
    if (progressEvent.isProgressChangeEvent!) {
      event = MapboxTurnByTurnEvent(
          eventType: MapboxEventType.progressChange, data: progressEvent);
    } else {
      event = MapboxTurnByTurnEvent.fromJson(map);
    }
    return event;
  }
}
