import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

import 'package:device_info_plus/device_info_plus.dart';

int sdkVersion = 0;

// The widget that show the mapbox MapView
class MapView extends StatelessWidget {
  MapView({Key? key}) : super(key: key) {
    getSdkVersion();
  }

  getSdkVersion() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      sdkVersion = androidInfo.version.sdkInt!;
    } else {
      sdkVersion = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'MapView';

    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (sdkVersion < 29) {
          return AndroidView(
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          );
        }

        return const Center(
          child: Text("SDK is greater then 29"),
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
}
