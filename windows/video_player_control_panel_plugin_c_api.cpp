#include "include/video_player_control_panel/video_player_control_panel_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "video_player_control_panel_plugin.h"

void VideoPlayerControlPanelPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  video_player_control_panel::VideoPlayerControlPanelPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
