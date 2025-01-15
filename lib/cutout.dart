import 'cutout_platform_interface.dart';

class Cutout {
  Future<String?> getPlatformVersion() {
    return CutoutPlatform.instance.getPlatformVersion();
  }
}
