// ignore_for_file: unused_field, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as logger;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';

import 'package:flutter_mapbox_turn_by_turn/flutter_mapbox_turn_by_turn.dart';
import 'package:latlong2/latlong.dart';

import 'components/orientation_button.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late bool _hasPermission = false;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  static LatLng? _pastLocation;
  static LatLng? _currentLocation;
  static LatLng? _pastEnhancedLocation;
  static LatLng? _currentEnhancedLocation;
  String _instruction = "";

  late final MapView _mapView;
  late final OrientationButton _orientationButton;

  @override
  void initState() {
    super.initState();
    initPermissionState();

    _mapView = MapView(
      eventNotifier: _onMapboxEvent,
      onInitializationFinished: _onInitializationFinished,
      zoom: 20,
      pitch: 75,
      navigateOnLongClick: true,
      showStopButton: true,
      routeDefaultColor: const Color(0xFF00FF0D),
      routeCasingColor: const Color(0xFF00FF0D),
      routeLowCongestionColor: const Color(0xFF00FF0D),
      routeUnknownCongestionColor: const Color(0xFF00FF0D),
      language: Language.englishUK,
    );

    _orientationButton = const OrientationButton();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPermissionState() async {
    bool hasPermission;

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    hasPermission = await _requestPermission();

    setState(() {
      _hasPermission = hasPermission;
    });
  }

  static Future<bool> _requestPermission() async {
    try {
      return await FlutterMapboxTurnByTurn.hasPermission();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Turn By Turn Example'),
          actions: <Widget>[
            Visibility(
              visible: _hasPermission,
              child: _orientationButton,
            ),
            IconButton(
              onPressed: () {
                _mapView.startNavigation(
                  waypoints: <Waypoint>[
                    Waypoint(
                      name: "Sydney Operahouse",
                      latitude: -33.85659,
                      longitude: 151.21528,
                    ),
                  ],
                  navigationCameraType: NavigationCameraType.overview,
                );
              },
              icon: const Icon(FontAwesome.map_o),
            ),
            IconButton(
              onPressed: () {
                _mapView.addOfflineMap(
                  mapStyleUrl:
                      'mapbox://styles/computerlinkau/clcqwxzco000y16p5e6im2riy',
                  maxZoom: 24,
                  areaId: '51',
                  centerLatitude: -27.557667575031797,
                  centerLongitude: 153.0225135375545,
                  distance: 20,
                );
              },
              icon: const Icon(FontAwesome.download),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: Visibility(
          visible: _hasPermission,
          replacement: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 5,
              end: 5,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Location permission required.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      bool hasPermission = await _requestPermission();

                      setState(() {
                        _hasPermission = hasPermission;
                      });
                    },
                    child: const Text(
                      "Request Permission",
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: Center(
            child: _mapView,
          ),
        ),
      ),
    );
  }

  /// Optional function to run after map initialization is complete
  Future<void> _onInitializationFinished() async {
    logger.log(
      'Initialization finished function called',
    );
  }

  /// Optional event handler if you want to listen to certain events such as
  /// navigation instruction or location changes
  void _onMapboxEvent(e) async {
    switch (e.eventType) {
      case MapboxEventType.progressChange:
        var progressChangeEvent = e.data as MapboxProgressChangeEvent;
        if (progressChangeEvent.currentStepInstruction != null) {
          _instruction = progressChangeEvent.currentStepInstruction!;
          logger.log(
            'Progress changed: $_instruction',
          );
        }
        break;
      case MapboxEventType.locationChange:
        var locationChangeEvent = e.data as MapboxLocationChangeEvent;

        _currentLocation = LatLng(
          locationChangeEvent.latitude!,
          locationChangeEvent.longitude!,
        );

        if (_pastLocation == null) {
          logger.log(
            'Location changed. Latitude: ${locationChangeEvent.latitude} Longitude: ${locationChangeEvent.longitude}',
          );

          _pastLocation = _currentLocation;
        } else {
          const Distance distance = Distance();

          if (distance(
                _pastLocation!,
                _currentLocation!,
              ) >
              4) {
            logger.log(
              'Location changed. Latitude: ${locationChangeEvent.latitude} Longitude: ${locationChangeEvent.longitude}',
            );

            _pastLocation = _currentLocation;
          }
        }
        break;
      case MapboxEventType.enhancedLocationChange:
        var locationChangeEvent = e.data as MapboxEnhancedLocationChangeEvent;

        _currentEnhancedLocation = LatLng(
          locationChangeEvent.latitude!,
          locationChangeEvent.longitude!,
        );

        if (_pastEnhancedLocation == null) {
          logger.log(
            'Enhanced Location changed. Latitude: ${locationChangeEvent.latitude} Longitude: ${locationChangeEvent.longitude}',
          );

          _pastEnhancedLocation = _currentEnhancedLocation;
        } else {
          const Distance distance = Distance();

          if (distance(
                _pastEnhancedLocation!,
                _currentEnhancedLocation!,
              ) >
              4) {
            logger.log(
              'Enhanced Location changed. Latitude: ${locationChangeEvent.latitude} Longitude: ${locationChangeEvent.longitude}',
            );

            _pastEnhancedLocation = _currentEnhancedLocation;
          }
        }
        break;
      case MapboxEventType.muteChanged:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log(
          'Are instructions muted? ${data['muted']}',
        );
        break;
      case MapboxEventType.routeBuilt:
        logger.log('Route built');
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapboxEventType.routeBuildFailed:
        logger.log('Route build failed');
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapboxEventType.navigationRunning:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapboxEventType.waypointArrival:
        logger.log("Waypoint reached");
        break;
      case MapboxEventType.nextRouteLegStart:
        logger.log("Starting next leg");
        break;
      case MapboxEventType.finalDestinationArrival:
        logger.log('Arrived at final destination');
        await Future.delayed(
          const Duration(
            seconds: 3,
          ),
        );
        await _mapView.stopNavigation();
        break;
      case MapboxEventType.navigationCancelled:
        logger.log('Navigation stopped');
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      case MapboxEventType.navigationCameraChanged:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log(
          'Navigation camera changed to : ${data['state']}',
        );
        break;
      case MapboxEventType.stylePackProgress:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log(
          'Offline style pack loading progress: ${data['percent']}%',
        );
        break;
      case MapboxEventType.stylePackFinished:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log('Offline style pack loading finished');
        break;
      case MapboxEventType.stylePackError:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log('Offline style pack loading error: ${data['error']}');
        break;
      case MapboxEventType.tileRegionProgress:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log(
          'Offline tile region ${data['id']} loading progress: ${data['percent']}%',
        );
        break;
      case MapboxEventType.tileRegionFinished:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log('Offline tile region ${data['id']} loading finished');
        break;
      case MapboxEventType.tileRegionError:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log(
            'Offline tile region ${data['id']} loading error: ${data['error']}');
        break;
      default:
        String jsonString = e.data as String;
        dynamic data = json.decode(jsonString);
        logger.log('Unrecognized event ${e.eventType} with data: $data');
        break;
    }
    setState(() {});
  }
}
