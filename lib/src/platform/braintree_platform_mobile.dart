import 'package:flutter/services.dart';

import '../request.dart';
import '../result.dart';
import 'braintree_platform.dart';

/// Mobile (Android/iOS) implementation of [BraintreePlatform] using MethodChannel.
///
/// This implementation delegates to native code via two MethodChannels:
/// - `flutter_braintree.custom` for credit card and PayPal tokenization
/// - `flutter_braintree.drop_in` for the native Drop-in UI
class MethodChannelBraintreePlatform extends BraintreePlatform {
  static const MethodChannel _customChannel =
      MethodChannel('flutter_braintree.custom');

  static const MethodChannel _dropInChannel =
      MethodChannel('flutter_braintree.drop_in');

  @override
  Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  ) async {
    final result = await _customChannel.invokeMethod('tokenizeCreditCard', {
      'authorization': authorization,
      'request': request.toJson(),
    });
    if (result == null) return null;
    return BraintreePaymentMethodNonce.fromJson(result);
  }

  @override
  Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  ) async {
    final result = await _customChannel.invokeMethod('requestPaypalNonce', {
      'authorization': authorization,
      'request': request.toJson(),
    });
    if (result == null) return null;
    return BraintreePaymentMethodNonce.fromJson(result);
  }

  @override
  Future<BraintreeDropInResult?> startDropIn(
      BraintreeDropInRequest request) async {
    final result = await _dropInChannel.invokeMethod(
      'start',
      request.toJson(),
    );
    if (result == null) return null;
    return BraintreeDropInResult.fromJson(result);
  }
}
