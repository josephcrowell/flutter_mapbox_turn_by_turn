import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

import 'package:device_info_plus/device_info_plus.dart';

int sdkVersion = 0;

// The widget that show the mapbox MapView
class MapView extends StatelessWidget {
  MapView({
    Key? key,
    this.mapStyleUrlDay,
    this.mapStyleUrlNight,
    this.navigateOnLongClick,
  }) : super(key: key) {
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

  final String? mapStyleUrlDay;
  final String? mapStyleUrlNight;
  final bool? navigateOnLongClick;

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'MapView';

    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{
      "mapStyleUrlDay": mapStyleUrlDay,
      "mapStyleUrlNight": mapStyleUrlNight,
      "navigateOnLongClick": navigateOnLongClick,
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
}
