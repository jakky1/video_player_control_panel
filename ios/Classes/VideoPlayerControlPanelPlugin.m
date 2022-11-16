#import "VideoPlayerControlPanelPlugin.h"
#if __has_include(<video_player_control_panel/video_player_control_panel-Swift.h>)
#import <video_player_control_panel/video_player_control_panel-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "video_player_control_panel-Swift.h"
#endif

@implementation VideoPlayerControlPanelPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftVideoPlayerControlPanelPlugin registerWithRegistrar:registrar];
}
@end
