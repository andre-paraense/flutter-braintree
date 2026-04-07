import 'braintree_platform.dart';

/// Stub implementation that throws [UnsupportedError].
///
/// This is used as a fallback when no platform-specific implementation
/// is available (i.e., when neither `dart:io` nor `dart:js_interop` is present).
BraintreePlatform createPlatform() =>
    throw UnsupportedError('No platform implementation found');
