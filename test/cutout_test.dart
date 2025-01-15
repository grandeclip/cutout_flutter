import 'package:flutter_test/flutter_test.dart';
import 'package:cutout/cutout.dart';
import 'package:cutout/cutout_platform_interface.dart';
import 'package:cutout/cutout_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCutoutPlatform
    with MockPlatformInterfaceMixin
    implements CutoutPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CutoutPlatform initialPlatform = CutoutPlatform.instance;

  test('$MethodChannelCutout is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCutout>());
  });

  test('getPlatformVersion', () async {
    Cutout cutoutPlugin = Cutout();
    MockCutoutPlatform fakePlatform = MockCutoutPlatform();
    CutoutPlatform.instance = fakePlatform;

    expect(await cutoutPlugin.getPlatformVersion(), '42');
  });
}
