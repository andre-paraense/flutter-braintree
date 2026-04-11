import 'package:flutter/services.dart';

import '../request.dart';
import '../result.dart';
import 'braintree_platform.dart';

/// Mobile (Android/iOS) implementation using MethodChannels.
///
/// This preserves the existing behavior of communicating with native code
/// through Flutter's MethodChannel mechanism.
class BraintreePlatformIo extends BraintreePlatform {
  static const _dropInChannel = MethodChannel('flutter_braintree.drop_in');
  static const _customChannel = MethodChannel('flutter_braintree.custom');

  @override
  Future<BraintreeDropInResult?> startDropIn(
      BraintreeDropInRequest request) async {
    var result = await _dropInChannel.invokeMethod(
      'start',
      request.toJson(),
    );
    if (result == null) return null;
    return BraintreeDropInResult.fromJson(result);
  }

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
}

BraintreePlatform createPlatform() => BraintreePlatformIo();
