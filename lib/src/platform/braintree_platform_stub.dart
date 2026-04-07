import 'braintree_platform.dart';

/// Creates a [BraintreePlatform] instance for the current platform.
///
/// This stub is used when the platform is not recognized (neither mobile nor web).
/// It throws an [UnsupportedError] to provide a clear error message.
BraintreePlatform createPlatform() {
  throw UnsupportedError(
    'flutter_braintree is not supported on this platform. '
    'Supported platforms: Android, iOS, and Web.',
  );
}
