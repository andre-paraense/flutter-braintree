import 'braintree_platform.dart';
import 'braintree_platform_web.dart';

/// Creates a [BraintreePlatform] instance for web.
///
/// This factory is selected via conditional import when `dart:js_interop` is available.
BraintreePlatform createPlatform() {
  return WebBraintreePlatform();
}
