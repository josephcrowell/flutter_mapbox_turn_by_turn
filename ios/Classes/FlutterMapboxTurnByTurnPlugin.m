#import "FlutterMapboxTurnByTurnPlugin.h"
#if __has_include(<flutter_mapbox_turn_by_turn/flutter_mapbox_turn_by_turn-Swift.h>)
#import <flutter_mapbox_turn_by_turn/flutter_mapbox_turn_by_turn-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_mapbox_turn_by_turn-Swift.h"
#endif

@implementation FlutterMapboxTurnByTurnPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMapboxTurnByTurnPlugin registerWithRegistrar:registrar];
}
@end
