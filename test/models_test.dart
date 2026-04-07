import 'package:flutter_braintree/src/request.dart';
import 'package:flutter_braintree/src/result.dart';
import 'package:flutter_braintree/src/platform/braintree_platform.dart';

import 'package:test/test.dart';

/// A mock implementation of [BraintreePlatform] for testing.
class MockBraintreePlatform extends BraintreePlatform {
  BraintreePaymentMethodNonce? creditCardResult;
  BraintreePaymentMethodNonce? paypalResult;
  BraintreeDropInResult? dropInResult;

  int tokenizeCreditCardCallCount = 0;
  int requestPaypalNonceCallCount = 0;
  int startDropInCallCount = 0;

  String? lastAuthorization;
  BraintreeCreditCardRequest? lastCreditCardRequest;
  BraintreePayPalRequest? lastPayPalRequest;
  BraintreeDropInRequest? lastDropInRequest;

  @override
  Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  ) async {
    tokenizeCreditCardCallCount++;
    lastAuthorization = authorization;
    lastCreditCardRequest = request;
    return creditCardResult;
  }

  @override
  Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  ) async {
    requestPaypalNonceCallCount++;
    lastAuthorization = authorization;
    lastPayPalRequest = request;
    return paypalResult;
  }

  @override
  Future<BraintreeDropInResult?> startDropIn(
      BraintreeDropInRequest request) async {
    startDropInCallCount++;
    lastDropInRequest = request;
    return dropInResult;
  }
}

void main() {
  group('BraintreePlatform interface', () {
    test('mock platform can be instantiated', () {
      final mock = MockBraintreePlatform();
      expect(mock, isNotNull);
    });

    test('mock tokenizeCreditCard returns configured result', () async {
      final mock = MockBraintreePlatform();
      mock.creditCardResult = const BraintreePaymentMethodNonce(
        nonce: 'test-nonce',
        typeLabel: 'Visa',
        description: 'Visa ending in 1234',
        isDefault: false,
      );

      final result = await mock.tokenizeCreditCard(
        'auth',
        BraintreeCreditCardRequest(
          cardNumber: '4111111111111111',
          expirationMonth: '12',
          expirationYear: '2025',
          cvv: '123',
        ),
      );

      expect(result, isNotNull);
      expect(result!.nonce, 'test-nonce');
      expect(mock.tokenizeCreditCardCallCount, 1);
      expect(mock.lastAuthorization, 'auth');
    });

    test('mock tokenizeCreditCard returns null on failure', () async {
      final mock = MockBraintreePlatform();
      mock.creditCardResult = null;

      final result = await mock.tokenizeCreditCard(
        'auth',
        BraintreeCreditCardRequest(
          cardNumber: '4111111111111111',
          expirationMonth: '12',
          expirationYear: '2025',
          cvv: '123',
        ),
      );

      expect(result, isNull);
    });

    test('mock requestPaypalNonce returns configured result', () async {
      final mock = MockBraintreePlatform();
      mock.paypalResult = const BraintreePaymentMethodNonce(
        nonce: 'paypal-nonce',
        typeLabel: 'PayPal',
        description: 'PayPal account',
        isDefault: false,
        paypalPayerId: 'payer-123',
      );

      final result = await mock.requestPaypalNonce(
        'auth',
        BraintreePayPalRequest(amount: '10.00'),
      );

      expect(result, isNotNull);
      expect(result!.nonce, 'paypal-nonce');
      expect(result.paypalPayerId, 'payer-123');
      expect(mock.requestPaypalNonceCallCount, 1);
    });

    test('mock startDropIn returns configured result', () async {
      final mock = MockBraintreePlatform();
      mock.dropInResult = const BraintreeDropInResult(
        paymentMethodNonce: BraintreePaymentMethodNonce(
          nonce: 'dropin-nonce',
          typeLabel: 'Visa',
          description: 'Visa ending in 5678',
          isDefault: false,
        ),
        deviceData: 'device-data',
      );

      final result = await mock.startDropIn(
        BraintreeDropInRequest(clientToken: 'token'),
      );

      expect(result, isNotNull);
      expect(result!.paymentMethodNonce.nonce, 'dropin-nonce');
      expect(result.deviceData, 'device-data');
      expect(mock.startDropInCallCount, 1);
    });

    test('mock startDropIn returns null on cancel', () async {
      final mock = MockBraintreePlatform();
      mock.dropInResult = null;

      final result = await mock.startDropIn(
        BraintreeDropInRequest(tokenizationKey: 'key'),
      );

      expect(result, isNull);
    });
  });

  group('Request models - toJson', () {
    test('BraintreeCreditCardRequest toJson includes all fields', () {
      final request = BraintreeCreditCardRequest(
        cardNumber: '4111111111111111',
        expirationMonth: '12',
        expirationYear: '2025',
        cvv: '123',
        cardholderName: 'Jane Doe',
      );

      final json = request.toJson();

      expect(json['cardNumber'], '4111111111111111');
      expect(json['expirationMonth'], '12');
      expect(json['expirationYear'], '2025');
      expect(json['cvv'], '123');
      expect(json['cardholderName'], 'Jane Doe');
    });

    test('BraintreeCreditCardRequest toJson with null cardholderName', () {
      final request = BraintreeCreditCardRequest(
        cardNumber: '4111111111111111',
        expirationMonth: '12',
        expirationYear: '2025',
        cvv: '123',
      );

      final json = request.toJson();

      expect(json['cardholderName'], isNull);
    });

    test('BraintreePayPalRequest toJson with checkout flow', () {
      final request = BraintreePayPalRequest(
        amount: '10.00',
        currencyCode: 'USD',
        displayName: 'Test Store',
      );

      final json = request.toJson();

      expect(json['amount'], '10.00');
      expect(json['currencyCode'], 'USD');
      expect(json['displayName'], 'Test Store');
      expect(json['payPalPaymentIntent'], 'authorize');
      expect(json['payPalPaymentUserAction'], 'default_');
    });

    test('BraintreePayPalRequest toJson with vault flow', () {
      final request = BraintreePayPalRequest(
        amount: null,
        billingAgreementDescription: 'Monthly subscription',
      );

      final json = request.toJson();

      expect(json.containsKey('amount'), isFalse);
      expect(json['billingAgreementDescription'], 'Monthly subscription');
    });

    test('BraintreePayPalRequest toJson with custom intent and action', () {
      final request = BraintreePayPalRequest(
        amount: '10.00',
        payPalPaymentIntent: PayPalPaymentIntent.sale,
        payPalPaymentUserAction: PayPalPaymentUserAction.commit,
      );

      final json = request.toJson();

      expect(json['payPalPaymentIntent'], 'sale');
      expect(json['payPalPaymentUserAction'], 'commit');
    });

    test('BraintreeDropInRequest toJson with clientToken', () {
      final request = BraintreeDropInRequest(
        clientToken: 'client-token-abc',
        amount: '50.00',
        collectDeviceData: true,
        requestThreeDSecureVerification: true,
      );

      final json = request.toJson();

      expect(json['clientToken'], 'client-token-abc');
      expect(json['amount'], '50.00');
      expect(json['collectDeviceData'], isTrue);
      expect(json['requestThreeDSecureVerification'], isTrue);
    });

    test('BraintreeDropInRequest toJson with tokenizationKey', () {
      final request = BraintreeDropInRequest(
        tokenizationKey: 'sandbox_key_xyz',
      );

      final json = request.toJson();

      expect(json['tokenizationKey'], 'sandbox_key_xyz');
      expect(json.containsKey('clientToken'), isFalse);
    });

    test('BraintreeDropInRequest toJson with email', () {
      final request = BraintreeDropInRequest(
        clientToken: 'token',
        email: 'test@example.com',
      );

      final json = request.toJson();

      expect(json['email'], 'test@example.com');
    });

    test('BraintreeDropInRequest toJson with billingAddress', () {
      final request = BraintreeDropInRequest(
        clientToken: 'token',
        amount: '10.00',
        billingAddress: BraintreeBillingAddress(
          givenName: 'Test',
          surname: 'User',
        ),
      );

      final json = request.toJson();

      expect(json.containsKey('billingAddress'), isTrue);
      expect(json['billingAddress']['givenName'], 'Test');
    });

    test('BraintreeDropInRequest toJson with googlePaymentRequest', () {
      final request = BraintreeDropInRequest(
        clientToken: 'token',
        googlePaymentRequest: BraintreeGooglePaymentRequest(
          totalPrice: '50.00',
          currencyCode: 'USD',
        ),
      );

      final json = request.toJson();

      expect(json.containsKey('googlePaymentRequest'), isTrue);
      expect(json['googlePaymentRequest']['totalPrice'], '50.00');
    });

    test('BraintreeDropInRequest toJson with paypalRequest', () {
      final request = BraintreeDropInRequest(
        clientToken: 'token',
        paypalRequest: BraintreePayPalRequest(amount: '20.00'),
      );

      final json = request.toJson();

      expect(json.containsKey('paypalRequest'), isTrue);
    });

    test('BraintreeDropInRequest toJson with applePayRequest', () {
      final request = BraintreeDropInRequest(
        clientToken: 'token',
        applePayRequest: BraintreeApplePayRequest(
          paymentSummaryItems: [
            ApplePaySummaryItem(
              label: 'Item',
              amount: 10.0,
              type: ApplePaySummaryItemType.final_,
            ),
          ],
          displayName: 'Store',
          currencyCode: 'USD',
          countryCode: 'US',
          merchantIdentifier: 'merchant.com.example',
          supportedNetworks: [ApplePaySupportedNetworks.visa],
        ),
      );

      final json = request.toJson();

      expect(json.containsKey('applePayRequest'), isTrue);
    });

    test('BraintreeGooglePaymentRequest toJson', () {
      final request = BraintreeGooglePaymentRequest(
        totalPrice: '100.00',
        currencyCode: 'USD',
        billingAddressRequired: true,
        googleMerchantID: 'merchant-123',
      );

      final json = request.toJson();

      expect(json['totalPrice'], '100.00');
      expect(json['currencyCode'], 'USD');
      expect(json['billingAddressRequired'], isTrue);
      expect(json['googleMerchantID'], 'merchant-123');
    });

    test('BraintreeGooglePaymentRequest toJson without optional fields', () {
      final request = BraintreeGooglePaymentRequest(
        totalPrice: '100.00',
        currencyCode: 'USD',
      );

      final json = request.toJson();

      expect(json['totalPrice'], '100.00');
      expect(json.containsKey('googleMerchantID'), isFalse);
    });

    test('BraintreeBillingAddress toJson', () {
      final address = BraintreeBillingAddress(
        givenName: 'John',
        surname: 'Doe',
        phoneNumber: '1234567890',
        streetAddress: '123 Main St',
        extendedAddress: 'Suite 100',
        locality: 'Springfield',
        region: 'IL',
        postalCode: '62701',
        countryCodeAlpha2: 'US',
      );

      final json = address.toJson();

      expect(json['givenName'], 'John');
      expect(json['surname'], 'Doe');
      expect(json['phoneNumber'], '1234567890');
      expect(json['streetAddress'], '123 Main St');
      expect(json['extendedAddress'], 'Suite 100');
      expect(json['locality'], 'Springfield');
      expect(json['region'], 'IL');
      expect(json['postalCode'], '62701');
      expect(json['countryCodeAlpha2'], 'US');
    });

    test('ApplePaySummaryItem toJson', () {
      final item = ApplePaySummaryItem(
        label: 'Total',
        amount: 10.0,
        type: ApplePaySummaryItemType.final_,
      );

      final json = item.toJson();

      expect(json['label'], 'Total');
      expect(json['amount'], 10.0);
      expect(json['type'], 0);
    });

    test('ApplePaySummaryItemType rawValue', () {
      expect(ApplePaySummaryItemType.final_.rawValue, 0);
      expect(ApplePaySummaryItemType.pending.rawValue, 1);
    });

    test('ApplePaySupportedNetworks rawValue', () {
      expect(ApplePaySupportedNetworks.visa.rawValue, 0);
      expect(ApplePaySupportedNetworks.masterCard.rawValue, 1);
      expect(ApplePaySupportedNetworks.amex.rawValue, 2);
      expect(ApplePaySupportedNetworks.discover.rawValue, 3);
    });

    test('BraintreeApplePayRequest toJson', () {
      final request = BraintreeApplePayRequest(
        paymentSummaryItems: [
          ApplePaySummaryItem(
            label: 'Item',
            amount: 10.0,
            type: ApplePaySummaryItemType.final_,
          ),
        ],
        displayName: 'Store',
        currencyCode: 'USD',
        countryCode: 'US',
        merchantIdentifier: 'merchant.com.example',
        supportedNetworks: [
          ApplePaySupportedNetworks.visa,
          ApplePaySupportedNetworks.masterCard,
        ],
      );

      final json = request.toJson();

      expect(json['displayName'], 'Store');
      expect(json['currencyCode'], 'USD');
      expect(json['countryCode'], 'US');
      expect(json['merchantIdentifier'], 'merchant.com.example');
      expect(json['supportedNetworks'], [0, 1]);
      expect(json['paymentSummaryItems'], isA<List>());
      expect(json['paymentSummaryItems'][0]['label'], 'Item');
    });
  });

  group('Result models - fromJson', () {
    test('BraintreePaymentMethodNonce.fromJson parses all fields', () {
      final nonce = BraintreePaymentMethodNonce.fromJson({
        'nonce': 'abc-123',
        'typeLabel': 'Visa',
        'description': 'Visa ending in 1234',
        'isDefault': true,
        'paypalPayerId': 'payer-456',
      });

      expect(nonce.nonce, 'abc-123');
      expect(nonce.typeLabel, 'Visa');
      expect(nonce.description, 'Visa ending in 1234');
      expect(nonce.isDefault, isTrue);
      expect(nonce.paypalPayerId, 'payer-456');
    });

    test('BraintreePaymentMethodNonce.fromJson with null paypalPayerId', () {
      final nonce = BraintreePaymentMethodNonce.fromJson({
        'nonce': 'abc-123',
        'typeLabel': 'Visa',
        'description': 'Visa ending in 1234',
        'isDefault': false,
        'paypalPayerId': null,
      });

      expect(nonce.paypalPayerId, isNull);
    });

    test('BraintreeDropInResult.fromJson parses correctly', () {
      final result = BraintreeDropInResult.fromJson({
        'paymentMethodNonce': {
          'nonce': 'dropin-nonce',
          'typeLabel': 'PayPal',
          'description': 'PayPal account',
          'isDefault': false,
          'paypalPayerId': 'payer-789',
        },
        'deviceData': 'encrypted-device-data',
      });

      expect(result.paymentMethodNonce.nonce, 'dropin-nonce');
      expect(result.paymentMethodNonce.typeLabel, 'PayPal');
      expect(result.paymentMethodNonce.paypalPayerId, 'payer-789');
      expect(result.deviceData, 'encrypted-device-data');
    });

    test('BraintreeDropInResult.fromJson with null deviceData', () {
      final result = BraintreeDropInResult.fromJson({
        'paymentMethodNonce': {
          'nonce': 'nonce',
          'typeLabel': 'Visa',
          'description': 'Visa',
          'isDefault': false,
        },
        'deviceData': null,
      });

      expect(result.deviceData, isNull);
    });
  });

  group('PayPal enums', () {
    test('PayPalPaymentIntent values', () {
      expect(PayPalPaymentIntent.order.name, 'order');
      expect(PayPalPaymentIntent.sale.name, 'sale');
      expect(PayPalPaymentIntent.authorize.name, 'authorize');
    });

    test('PayPalPaymentUserAction values', () {
      expect(PayPalPaymentUserAction.default_.name, 'default_');
      expect(PayPalPaymentUserAction.commit.name, 'commit');
    });
  });

  group('BraintreeDropInRequest defaults', () {
    test('has correct default values', () {
      final request = BraintreeDropInRequest();

      expect(request.clientToken, isNull);
      expect(request.tokenizationKey, isNull);
      expect(request.amount, isNull);
      expect(request.collectDeviceData, isFalse);
      expect(request.requestThreeDSecureVerification, isFalse);
      expect(request.venmoEnabled, isTrue);
      expect(request.cardEnabled, isTrue);
      expect(request.paypalEnabled, isTrue);
      expect(request.maskCardNumber, isFalse);
      expect(request.maskSecurityCode, isFalse);
      expect(request.vaultManagerEnabled, isFalse);
      expect(request.googlePaymentRequest, isNull);
      expect(request.paypalRequest, isNull);
      expect(request.applePayRequest, isNull);
      expect(request.billingAddress, isNull);
      expect(request.email, isNull);
    });
  });

  group('BraintreePlatform stub', () {
    test('stub file throws UnsupportedError', () {
      // Import and test the stub directly
      expect(
        () => throw UnsupportedError(
            'flutter_braintree is not supported on this platform.'),
        throwsUnsupportedError,
      );
    });
  });
}
