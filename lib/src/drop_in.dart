import 'dart:async';

import 'request.dart';
import 'result.dart';
import 'platform/braintree_platform_provider.dart';

class BraintreeDropIn {
  const BraintreeDropIn._();

  /// Launches the Braintree Drop-in UI.
  ///
  /// The required options can be placed inside the [request] object.
  /// See its documentation for more information.
  ///
  /// On mobile (Android/iOS), this launches the native Drop-in UI.
  /// On web, this shows a Braintree Drop-in overlay using the JavaScript SDK.
  ///
  /// Returns a Future that resolves to a [BraintreeDropInResult] containing
  /// all the relevant information, or `null` if the selection was canceled.
  static Future<BraintreeDropInResult?> start(
      BraintreeDropInRequest request) async {
    return braintreePlatform.startDropIn(request);
  }
}
