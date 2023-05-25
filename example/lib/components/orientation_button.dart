import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_font_icons/flutter_font_icons.dart';

/// OrientationButton provides a widget button to switch orientation for the entire app
class OrientationButton extends StatefulWidget {
  /// The constructor for the orientation button
  const OrientationButton({Key? key}) : super(key: key);

  @override
  State<OrientationButton> createState() => _OrientationButtonState();
}

class _OrientationButtonState extends State<OrientationButton> {
  Icon _buttonIcon = const Icon(MaterialCommunityIcons.phone_rotate_landscape);

  Future<dynamic> _orientationSwitch() async {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      List<DeviceOrientation> orientations = <DeviceOrientation>[
        DeviceOrientation.landscapeLeft
      ];
      await SystemChrome.setPreferredOrientations(orientations);
      _buttonIcon = const Icon(MaterialCommunityIcons.phone_rotate_portrait);
    } else {
      List<DeviceOrientation> orientations = <DeviceOrientation>[
        DeviceOrientation.portraitUp
      ];
      await SystemChrome.setPreferredOrientations(orientations);
      _buttonIcon = const Icon(MaterialCommunityIcons.phone_rotate_landscape);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _buttonIcon,
      iconSize: 30,
      onPressed: _orientationSwitch,
    );
  }
}
