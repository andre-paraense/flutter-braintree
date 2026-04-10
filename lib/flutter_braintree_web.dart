import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web plugin registration for flutter_braintree.
///
/// Platform selection is handled automatically via conditional imports in
/// `src/platform/braintree_platform_provider.dart`. This class serves as the
/// standard Flutter web plugin entry point.
class FlutterBraintreeWebPlugin {
  static void registerWith(Registrar registrar) {
    // No-op: the web platform implementation is selected via conditional
    // imports in braintree_platform_provider.dart.
  }
}
