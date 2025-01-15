import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cutout_platform_interface.dart';

/// An implementation of [CutoutPlatform] that uses method channels.
class MethodChannelCutout extends CutoutPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cutout');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
