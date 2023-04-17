import 'dart:async';
import 'dart:convert';
import 'dart:developer' as logger;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mapbox_turn_by_turn/src/models/mapbox_progress_change_event.dart';
import 'package:flutter_mapbox_turn_by_turn/src/models/mapbox_turn_by_turn_event.dart';
import 'package:flutter_mapbox_turn_by_turn/src/models/waypoint.dart';

import 'package:flutter_tts/flutter_tts.dart';

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

/// What you want the navigation camera to do when starting navigation
class NavigationCameraType {
  /// Don't change hte camera type when starting navigation
  static const String noChange = "noChange";

  /// Switch the camera to overview when starting navigation
  static const String overview = "overview";

  /// Switch the camera to following when starting navigation
  static const String following = "following";
}

Stream<MapboxTurnByTurnEvent>? _onMapboxTurnByTurnEvent;
FlutterTts _flutterTts = FlutterTts();
List<String> _instructions = <String>[];

// The widget that show the mapbox MapView
class MapView extends StatelessWidget {
  final MethodChannel _methodChannel =
      const MethodChannel('flutter_mapbox_turn_by_turn/map_view/method');
  final EventChannel _eventChannel =
      const EventChannel('flutter_mapbox_turn_by_turn/map_view/events');

  MapView({
    Key? key,
    this.eventNotifier,
    this.onInitializationFinished,
    this.zoom,
    this.pitch,
    this.disableGesturesWhenFollowing,
    this.navigateOnLongClick,
    this.muted,
    this.showMuteButton,
    this.showStopButton,
    this.showSpeedIndicator,
    this.navigationCameraType,
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
    _methodChannel.setMethodCallHandler(_handleMethod);

    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
    _flutterTts.setVolume(0.5);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _flutterTts.setSharedInstance(true);

      _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt);
    }

    _instructionProcessTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (Timer timer) {
        _processInstructionCache();
      },
    );
  }

  final ValueSetter<MapboxTurnByTurnEvent>? eventNotifier;
  late final StreamSubscription<MapboxTurnByTurnEvent>?
      _mapboxTurnByTurnEventSubscription;
  late final Function? onInitializationFinished;
  static bool _instructionPlaying = false;

  late Timer _instructionProcessTimer;

  final double? zoom;
  final double? pitch;
  final bool? disableGesturesWhenFollowing;
  final bool? navigateOnLongClick;
  final bool? muted;
  final bool? showMuteButton;
  final bool? showStopButton;
  final bool? showSpeedIndicator;
  final String? navigationCameraType;
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
      "disableGesturesWhenFollowing": disableGesturesWhenFollowing ?? true,
      "navigateOnLongClick": navigateOnLongClick,
      "muted": muted,
      "showMuteButton": showMuteButton ?? true,
      "showStopButton": showStopButton ?? true,
      "showSpeedIndicator": showSpeedIndicator ?? true,
      "navigationCameraType":
          navigationCameraType ?? NavigationCameraType.overview,
      "routeProfile": routeProfile ?? RouteProfile.drivingTraffic,
      "language": language ?? Language.englishUS,
      "measurementUnits": measurementUnits ?? MeasurementUnits.metric,
      "speedThreshold": speedThreshold ?? 5,
      "showAlternativeRoutes": showAlternativeRoutes ?? false,
      "allowUTurnsAtWaypoints": allowUTurnsAtWaypoints ?? false,
      "mapStyleUrlDay":
          mapStyleUrlDay ?? 'mapbox://styles/mapbox/navigation-day-v1',
      "mapStyleUrlNight":
          mapStyleUrlNight ?? 'mapbox://styles/mapbox/navigation-night-v1',
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
            return PlatformViewsService.initExpensiveAndroidView(
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

  /// Clean up the timer object
  void dispose() {
    _instructionProcessTimer.cancel();
    _mapboxTurnByTurnEventSubscription?.cancel();
  }

  static Future<dynamic> _processInstructionCache() async {
    if (!_instructionPlaying && _instructions.isNotEmpty) {
      _instructionPlaying = true;

      String currentInstruction = _instructions.elementAt(0);

      logger.log("Voice instruction: $currentInstruction");

      if (await _flutterTts.speak(currentInstruction) == 1) {
        _instructions.removeAt(0);
      }

      _instructionPlaying = false;
    }
  }

  /// Generic Handler for Messages sent from the Platform
  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onInitializationFinished':
        if (eventNotifier != null) {
          _mapboxTurnByTurnEventSubscription =
              _eventStream!.listen(_onEventData);
          logger.log('Event Notifier is initialized');
        } else {
          logger.log('Event Notifier is not initialized because it is null');
        }

        if (onInitializationFinished != null) {
          onInitializationFinished!();
        }

        break;
      case 'playVoiceInstruction':
        _instructions.add(call.arguments);
        break;
    }
  }

  /// Starts the Navigation
  Future<bool?> startNavigation({
    required List<Waypoint> waypoints,
    String? navigationCameraType,
  }) async {
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
    args["navigationCameraType"] =
        navigationCameraType ?? NavigationCameraType.noChange;
    return _methodChannel.invokeMethod('startNavigation', args);
  }

  /// Stops the navigation
  Future<bool?> stopNavigation() async {
    return _methodChannel.invokeMethod('stopNavigation');
  }

  /// Adds an offline map
  /// [mapStyleUrl] is the url of the map style to download an offline map for
  /// [areaId] is an id to give this region for retrieving it from storage
  /// [centerLatitude] is the latitude of the center of the region to download
  /// [centerLongitude] is the longitude of the center of the region to download
  /// [distance] is the distance from center that we want loaded
  Future<bool?> addOfflineMap({
    required String mapStyleUrl,
    int? minZoom,
    int? maxZoom,
    required String areaId,
    required double centerLatitude,
    required double centerLongitude,
    required double distance,
  }) async {
    var args = <String, dynamic>{};

    args["mapStyleUrl"] = mapStyleUrl;
    args["minZoom"] = minZoom ?? 0;
    args["maxZoom"] = maxZoom ?? 20;
    args["areaId"] = areaId;
    args["centerLatitude"] = centerLatitude;
    args["centerLongitude"] = centerLongitude;
    args["distance"] = distance;

    return _methodChannel.invokeMethod('addOfflineMap', args);
  }

  Future<void> toggleMuted() async {
    return _methodChannel.invokeMethod('toggleMuted');
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
