import 'platform/braintree_platform_provider.dart';

import 'request.dart';
import 'result.dart';

/// Provides custom Braintree payment tokenization functionality.
///
/// Supports credit card tokenization and PayPal payment nonce requests
/// across Android, iOS, and Web platforms.
class Braintree {
  const Braintree._();

  /// Tokenizes a credit card.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the credit card information necessary for tokenization.
  ///
  /// Returns a [Future] that resolves to a [BraintreePaymentMethodNonce] if the tokenization was successful.
  static Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  ) async {
    return BraintreePlatformProvider.instance
        .tokenizeCreditCard(authorization, request);
  }

  /// Requests a PayPal payment method nonce.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the information necessary for the PayPal request.
  ///
  /// Returns a [Future] that resolves to a [BraintreePaymentMethodNonce] if the user confirmed the request,
  /// or `null` if the user canceled the Vault or Checkout flow.
  static Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  ) async {
    return BraintreePlatformProvider.instance
        .requestPaypalNonce(authorization, request);
  }
}
