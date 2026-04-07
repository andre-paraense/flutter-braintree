import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web plugin registration for flutter_braintree.
///
/// This class is referenced in `pubspec.yaml` and is automatically called by
/// Flutter's web plugin registration system. The actual web implementation
/// uses conditional imports in the platform abstraction layer, so this class
/// only serves as the registration entry point.
class FlutterBraintreeWebPlugin {
  /// Registers this plugin with the Flutter web engine.
  static void registerWith(Registrar registrar) {
    // No method channel registration needed for web.
    // The web implementation uses direct JS interop via conditional imports.
  }
}
