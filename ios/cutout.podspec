#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cutout.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cutout'
  s.version          = '25.1.0'
  s.summary          = 'CutOut image segmentation Flutter package'
  s.description      = <<-DESC
Flutter package for CutOut image segmentation implementation that enables the utilization of C++ code for image processing.
                       DESC
  s.homepage         = 'https://github.com/grandeclip/cutout_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jongmin Park' => 'gzu@grandeclip.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'cutout_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  # telling CocoaPods not to remove framework
  s.preserve_paths = 'opencv2.framework' 

  # telling linker to include opencv2 framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework opencv2' }

  # including OpenCV framework
  s.vendored_frameworks = 'opencv2.framework' 

  # including native framework
  s.frameworks = 'AVFoundation'

  # including C++ library
  s.library = 'c++'
end
