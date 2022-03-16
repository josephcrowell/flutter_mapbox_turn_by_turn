import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_turn_by_turn/flutter_mapbox_turn_by_turn.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_mapbox_turn_by_turn');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterMapboxTurnByTurn.platformVersion, '42');
  });
}
