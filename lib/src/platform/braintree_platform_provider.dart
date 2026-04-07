import 'braintree_platform.dart';

// Conditional import: selects the appropriate factory function based on the platform.
// - On web (where dart:js_interop is available): uses create_platform_web.dart
// - On mobile/desktop (where dart:io is available): uses create_platform_mobile.dart
// - On unsupported platforms: uses braintree_platform_stub.dart (throws)
import 'braintree_platform_stub.dart'
    if (dart.library.js_interop) 'create_platform_web.dart'
    if (dart.library.io) 'create_platform_mobile.dart' as platform_factory;

/// Singleton instance of the current platform's [BraintreePlatform].
///
/// Lazily created on first access using the platform-specific factory
/// selected at compile time via conditional imports.
class BraintreePlatformProvider {
  BraintreePlatformProvider._();

  static BraintreePlatform? _instance;

  /// Returns the singleton [BraintreePlatform] instance for the current platform.
  ///
  /// The platform is automatically detected at compile time.
  /// On mobile: uses MethodChannel-based implementation.
  /// On web: uses JavaScript interop with Braintree Web SDK.
  static BraintreePlatform get instance {
    _instance ??= platform_factory.createPlatform();
    return _instance!;
  }

  /// Allows setting a custom platform instance (useful for testing).
  static set instance(BraintreePlatform platform) {
    _instance = platform;
  }

  /// Resets the platform instance to force re-creation.
  /// Primarily used for testing.
  static void reset() {
    _instance = null;
  }
}
