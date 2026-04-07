import 'dart:async';

import 'platform/braintree_platform_provider.dart';

import 'request.dart';
import 'result.dart';

/// Provides access to Braintree's Drop-in UI.
///
/// The Drop-in UI provides a pre-built payment form that supports credit cards,
/// PayPal, and other payment methods. Works across Android, iOS, and Web platforms.
class BraintreeDropIn {
  const BraintreeDropIn._();

  /// Launches the Braintree Drop-in UI.
  ///
  /// The required options can be placed inside the [request] object.
  /// See its documentation for more information.
  ///
  /// Returns a Future that resolves to a [BraintreeDropInResult] containing
  /// all the relevant information, or `null` if the selection was canceled.
  static Future<BraintreeDropInResult?> start(
      BraintreeDropInRequest request) async {
    return BraintreePlatformProvider.instance.startDropIn(request);
  }
}
