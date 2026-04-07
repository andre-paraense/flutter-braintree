import 'braintree_platform.dart';
import 'braintree_platform_mobile.dart';

/// Creates a [BraintreePlatform] instance for mobile (Android/iOS).
///
/// This factory is selected via conditional import when `dart:io` is available.
BraintreePlatform createPlatform() {
  return MethodChannelBraintreePlatform();
}
