import 'braintree_platform.dart';

import 'braintree_platform_stub.dart'
    if (dart.library.js_interop) 'braintree_platform_web.dart'
    if (dart.library.io) 'braintree_platform_io.dart';

/// Singleton [BraintreePlatform] instance.
///
/// On mobile (dart:io available) this returns the MethodChannel-based
/// implementation. On web (dart:js_interop available) this returns the
/// JS-interop-based implementation. Otherwise it throws.
final BraintreePlatform braintreePlatform = createPlatform();
