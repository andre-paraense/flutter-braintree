import '../request.dart';
import '../result.dart';

/// Abstract platform interface for Braintree operations.
///
/// This provides a common API that is implemented differently
/// for mobile (via MethodChannels) and web (via JS interop).
abstract class BraintreePlatform {
  /// Launches the Braintree Drop-in UI.
  ///
  /// Returns a [BraintreeDropInResult] containing the payment method nonce,
  /// or `null` if the user canceled.
  Future<BraintreeDropInResult?> startDropIn(BraintreeDropInRequest request);

  /// Tokenizes a credit card.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the credit card information necessary for tokenization.
  ///
  /// Returns a [BraintreePaymentMethodNonce] if the tokenization was successful,
  /// or `null` otherwise.
  Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  );

  /// Requests a PayPal payment method nonce.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the information necessary for the PayPal request.
  ///
  /// Returns a [BraintreePaymentMethodNonce] if the user confirmed the request,
  /// or `null` if the user canceled.
  Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  );
}
