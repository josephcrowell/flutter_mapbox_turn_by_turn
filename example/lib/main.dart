import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';

import 'package:flutter_mapbox_turn_by_turn/flutter_mapbox_turn_by_turn.dart';

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
  final MapView _mapView = MapView(
    zoom: 20,
    pitch: 75,
    mapStyleUrlDay: 'mapbox://styles/computerlinkau/cktnmg1zb0f6717mqtx5gb5c5',
    mapStyleUrlNight:
        'mapbox://styles/computerlinkau/ckqbt6y4k0akg17o6p90cz79d',
    navigateOnLongClick: true,
    showStopButton: true,
    routeDefaultColor: const Color(0xFF00FF0D),
    routeCasingColor: const Color(0xFF00FF0D),
    routeLowCongestionColor: const Color(0xFF00FF0D),
    routeUnknownCongestionColor: const Color(0xFF00FF0D),
    language: Language.englishUK,
  );

  @override
  void initState() {
    super.initState();
    initMapState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initMapState() async {
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
            IconButton(
              onPressed: () {
                _mapView.startNavigation(
                  waypoints: <Destination>[
                    Destination(
                      name: "Sydney Opera House",
                      latitude: -33.85659,
                      longitude: 151.21528,
                    ),
                  ],
                );
              },
              icon: const Icon(FontAwesome.map_o),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: Visibility(
          visible: _hasPermission,
          child: Center(
            child: _mapView,
          ),
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
        ),
      ),
    );
  }
}
