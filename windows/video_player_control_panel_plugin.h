#ifndef FLUTTER_PLUGIN_VIDEO_PLAYER_CONTROL_PANEL_PLUGIN_H_
#define FLUTTER_PLUGIN_VIDEO_PLAYER_CONTROL_PANEL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace video_player_control_panel {

class VideoPlayerControlPanelPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  VideoPlayerControlPanelPlugin();

  virtual ~VideoPlayerControlPanelPlugin();

  // Disallow copy and assign.
  VideoPlayerControlPanelPlugin(const VideoPlayerControlPanelPlugin&) = delete;
  VideoPlayerControlPanelPlugin& operator=(const VideoPlayerControlPanelPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace video_player_control_panel

#endif  // FLUTTER_PLUGIN_VIDEO_PLAYER_CONTROL_PANEL_PLUGIN_H_
