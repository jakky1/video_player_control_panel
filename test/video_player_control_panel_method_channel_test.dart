import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_control_panel/video_player_control_panel_method_channel.dart';

void main() {
  MethodChannelVideoPlayerControlPanel platform = MethodChannelVideoPlayerControlPanel();
  const MethodChannel channel = MethodChannel('video_player_control_panel');

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
    expect(await platform.getPlatformVersion(), '42');
  });
}
