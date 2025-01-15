import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cutout_method_channel.dart';

abstract class CutoutPlatform extends PlatformInterface {
  /// Constructs a CutoutPlatform.
  CutoutPlatform() : super(token: _token);

  static final Object _token = Object();

  static CutoutPlatform _instance = MethodChannelCutout();

  /// The default instance of [CutoutPlatform] to use.
  ///
  /// Defaults to [MethodChannelCutout].
  static CutoutPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CutoutPlatform] when
  /// they register themselves.
  static set instance(CutoutPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
