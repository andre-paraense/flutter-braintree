import '../request.dart';
import '../result.dart';

/// Abstract platform interface for Braintree operations.
///
/// Platform-specific implementations (mobile via MethodChannel, web via JS interop)
/// implement this interface to provide Braintree functionality.
abstract class BraintreePlatform {
  /// Tokenizes a credit card and returns a payment method nonce.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the credit card information necessary for tokenization.
  ///
  /// Returns a [Future] that resolves to a [BraintreePaymentMethodNonce] if the tokenization
  /// was successful, or `null` if it failed or was canceled.
  Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  );

  /// Requests a PayPal payment method nonce.
  ///
  /// [authorization] must be either a valid client token or a valid tokenization key.
  /// [request] should contain all the information necessary for the PayPal request.
  ///
  /// Returns a [Future] that resolves to a [BraintreePaymentMethodNonce] if the user confirmed
  /// the request, or `null` if the user canceled the Vault or Checkout flow.
  Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  );

  /// Launches the Braintree Drop-in UI.
  ///
  /// [request] contains the required options for the Drop-in UI.
  ///
  /// Returns a [Future] that resolves to a [BraintreeDropInResult] containing
  /// all the relevant information, or `null` if the selection was canceled.
  Future<BraintreeDropInResult?> startDropIn(BraintreeDropInRequest request);
}
