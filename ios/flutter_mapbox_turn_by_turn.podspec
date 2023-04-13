#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_mapbox_turn_by_turn.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_mapbox_turn_by_turn'
  s.version          = '0.0.1'
  s.summary          = 'Turn By Turn Navigation for Your Flutter Application.'
  s.description      = <<-DESC
Add Turn By Turn Navigation to Your Flutter Application Using MapBox.
                       DESC
  s.homepage         = 'https://github.com/AnnonAU/flutter_mapbox_turn_by_turn'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Annon Pty Ltd' => 'appsupport@annon.com.au' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'MapboxCoreNavigation', '~> 2.12.0'
  s.dependency 'MapboxNavigation', '~> 2.12.0'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.5'
end
