import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
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
  int _sdkVersion = -1;
  late bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    initMapState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initMapState() async {
    int sdkVersion;
    bool hasPermission;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      sdkVersion = await FlutterMapboxTurnByTurn.sdkVersion ?? -1;
    } on PlatformException {
      sdkVersion = 0;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    hasPermission = await _requestPermission();

    setState(() {
      _sdkVersion = sdkVersion;
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
          title: const Text('Flutter Mapbox Turn By Turn Example'),
        ),
        backgroundColor: Colors.black,
        body: Visibility(
          visible: _hasPermission,
          child: Center(
            child: MapView(),
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
