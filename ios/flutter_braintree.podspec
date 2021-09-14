#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_braintree'
  s.version          = '2.0.0'
  s.summary          = 'A Flutter plugin for Braintree'
  s.description      = <<-DESC
  A Flutter plugin that wraps the native Braintree Drop-In UI SDKs.
                       DESC
  s.homepage         = 'https://github.com/Pikaju/FlutterBraintree'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Julien Scholz' => '' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'BraintreeDropIn', '9.0.2'
  s.dependency 'Braintree/PayPal', '~> 5.3.2'
  s.dependency 'Braintree/ApplePay', '~> 5.3.2'
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.4'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end
