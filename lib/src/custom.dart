import 'request.dart';
import 'result.dart';
import 'platform/braintree_platform_provider.dart';

class Braintree {
  const Braintree._();

  /// Tokenizes a credit card.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the credit card information necessary for tokenization.
  ///
  /// On mobile (Android/iOS), this uses the native Braintree SDK.
  /// On web, this uses the Braintree JavaScript client SDK.
  ///
  /// Returns a [Future] that resolves to a [BraintreePaymentMethodNonce] if the tokenization was successful.
  static Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  ) async {
    return braintreePlatform.tokenizeCreditCard(authorization, request);
  }

  /// Requests a PayPal payment method nonce.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the information necessary for the PayPal request.
  ///
  /// On mobile (Android/iOS), this uses the native Braintree SDK.
  /// On web, this shows a PayPal button overlay using the JavaScript SDK.
  ///
  /// Returns a [Future] that resolves to a [BraintreePaymentMethodNonce] if the user confirmed the request,
  /// or `null` if the user canceled the Vault or Checkout flow.
  static Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  ) async {
    return braintreePlatform.requestPaypalNonce(authorization, request);
  }
}
