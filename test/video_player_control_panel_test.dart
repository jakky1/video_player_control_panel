import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_control_panel/video_player_control_panel.dart';
import 'package:video_player_control_panel/video_player_control_panel_platform_interface.dart';
import 'package:video_player_control_panel/video_player_control_panel_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoPlayerControlPanelPlatform
    with MockPlatformInterfaceMixin
    implements VideoPlayerControlPanelPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VideoPlayerControlPanelPlatform initialPlatform = VideoPlayerControlPanelPlatform.instance;

  test('$MethodChannelVideoPlayerControlPanel is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoPlayerControlPanel>());
  });

  test('getPlatformVersion', () async {
    VideoPlayerControlPanel videoPlayerControlPanelPlugin = VideoPlayerControlPanel();
    MockVideoPlayerControlPanelPlatform fakePlatform = MockVideoPlayerControlPanelPlatform();
    VideoPlayerControlPanelPlatform.instance = fakePlatform;

    expect(await videoPlayerControlPanelPlugin.getPlatformVersion(), '42');
  });
}
