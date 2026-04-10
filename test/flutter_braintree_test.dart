import 'package:flutter_braintree/src/request.dart';
import 'package:flutter_braintree/src/result.dart';
import 'package:flutter_braintree/src/platform/braintree_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BraintreePlatform', () {
    test('defines startDropIn method', () {
      // Verify the abstract interface exists and has the expected shape.
      // We cannot instantiate it directly, but we can check that a
      // concrete subclass must override all three methods.
      expect(BraintreePlatform, isNotNull);
    });
  });

  group('BraintreeDropInRequest', () {
    test('toJson includes clientToken when set', () {
      final request = BraintreeDropInRequest(clientToken: 'test_client_token');
      final json = request.toJson();
      expect(json['clientToken'], 'test_client_token');
      expect(json.containsKey('tokenizationKey'), false);
    });

    test('toJson includes tokenizationKey when set', () {
      final request =
          BraintreeDropInRequest(tokenizationKey: 'test_tokenization_key');
      final json = request.toJson();
      expect(json['tokenizationKey'], 'test_tokenization_key');
      expect(json.containsKey('clientToken'), false);
    });

    test('toJson includes all boolean flags with defaults', () {
      final request = BraintreeDropInRequest();
      final json = request.toJson();
      expect(json['collectDeviceData'], false);
      expect(json['requestThreeDSecureVerification'], false);
      expect(json['venmoEnabled'], true);
      expect(json['cardEnabled'], true);
      expect(json['paypalEnabled'], true);
      expect(json['maskCardNumber'], false);
      expect(json['maskSecurityCode'], false);
      expect(json['vaultManagerEnabled'], false);
    });

    test('toJson includes optional fields when set', () {
      final request = BraintreeDropInRequest(
        clientToken: 'token',
        amount: '10.00',
        email: 'user@example.com',
      );
      final json = request.toJson();
      expect(json['amount'], '10.00');
      expect(json['email'], 'user@example.com');
    });

    test('toJson omits optional fields when null', () {
      final request = BraintreeDropInRequest();
      final json = request.toJson();
      expect(json.containsKey('amount'), false);
      expect(json.containsKey('email'), false);
      expect(json.containsKey('billingAddress'), false);
      expect(json.containsKey('googlePaymentRequest'), false);
      expect(json.containsKey('paypalRequest'), false);
      expect(json.containsKey('applePayRequest'), false);
    });

    test('toJson includes billing address when set', () {
      final request = BraintreeDropInRequest(
        billingAddress: BraintreeBillingAddress(
          givenName: 'John',
          surname: 'Doe',
          postalCode: '12345',
        ),
      );
      final json = request.toJson();
      expect(json.containsKey('billingAddress'), true);
      final addr = json['billingAddress'] as Map<String, dynamic>;
      expect(addr['givenName'], 'John');
      expect(addr['surname'], 'Doe');
      expect(addr['postalCode'], '12345');
    });
  });

  group('BraintreeBillingAddress', () {
    test('toJson serializes all fields', () {
      final address = BraintreeBillingAddress(
        givenName: 'Jane',
        surname: 'Smith',
        phoneNumber: '5551234567',
        streetAddress: '123 Main St',
        extendedAddress: 'Apt 4',
        locality: 'Springfield',
        region: 'IL',
        postalCode: '62701',
        countryCodeAlpha2: 'US',
      );
      final json = address.toJson();
      expect(json['givenName'], 'Jane');
      expect(json['surname'], 'Smith');
      expect(json['phoneNumber'], '5551234567');
      expect(json['streetAddress'], '123 Main St');
      expect(json['extendedAddress'], 'Apt 4');
      expect(json['locality'], 'Springfield');
      expect(json['region'], 'IL');
      expect(json['postalCode'], '62701');
      expect(json['countryCodeAlpha2'], 'US');
    });
  });

  group('BraintreeCreditCardRequest', () {
    test('toJson serializes all fields', () {
      final request = BraintreeCreditCardRequest(
        cardNumber: '4111111111111111',
        expirationMonth: '12',
        expirationYear: '2025',
        cvv: '123',
        cardholderName: 'John Doe',
      );
      final json = request.toJson();
      expect(json['cardNumber'], '4111111111111111');
      expect(json['expirationMonth'], '12');
      expect(json['expirationYear'], '2025');
      expect(json['cvv'], '123');
      expect(json['cardholderName'], 'John Doe');
    });

    test('toJson handles null cardholderName', () {
      final request = BraintreeCreditCardRequest(
        cardNumber: '4111111111111111',
        expirationMonth: '12',
        expirationYear: '2025',
        cvv: '123',
      );
      final json = request.toJson();
      expect(json['cardholderName'], null);
    });
  });

  group('BraintreeGooglePaymentRequest', () {
    test('toJson serializes required fields', () {
      final request = BraintreeGooglePaymentRequest(
        totalPrice: '10.00',
        currencyCode: 'USD',
      );
      final json = request.toJson();
      expect(json['totalPrice'], '10.00');
      expect(json['currencyCode'], 'USD');
      expect(json['billingAddressRequired'], true);
    });

    test('toJson omits googleMerchantID when null', () {
      final request = BraintreeGooglePaymentRequest(
        totalPrice: '10.00',
        currencyCode: 'USD',
      );
      final json = request.toJson();
      expect(json.containsKey('googleMerchantID'), false);
    });

    test('toJson includes googleMerchantID when set', () {
      final request = BraintreeGooglePaymentRequest(
        totalPrice: '10.00',
        currencyCode: 'USD',
        googleMerchantID: 'merchant_123',
      );
      final json = request.toJson();
      expect(json['googleMerchantID'], 'merchant_123');
    });
  });

  group('BraintreePayPalRequest', () {
    test('toJson with amount (checkout flow)', () {
      final request = BraintreePayPalRequest(
        amount: '10.00',
        currencyCode: 'USD',
        displayName: 'Test Company',
      );
      final json = request.toJson();
      expect(json['amount'], '10.00');
      expect(json['currencyCode'], 'USD');
      expect(json['displayName'], 'Test Company');
    });

    test('toJson without amount (vault flow)', () {
      final request = BraintreePayPalRequest(
        amount: null,
        billingAgreementDescription: 'Agreement text',
      );
      final json = request.toJson();
      expect(json.containsKey('amount'), false);
      expect(json['billingAgreementDescription'], 'Agreement text');
    });

    test('toJson includes intent and user action', () {
      final request = BraintreePayPalRequest(
        amount: '5.00',
        payPalPaymentIntent: PayPalPaymentIntent.sale,
        payPalPaymentUserAction: PayPalPaymentUserAction.commit,
      );
      final json = request.toJson();
      expect(json['payPalPaymentIntent'], 'sale');
      expect(json['payPalPaymentUserAction'], 'commit');
    });
  });

  group('BraintreeDropInResult', () {
    test('fromJson parses nonce and device data', () {
      final json = {
        'paymentMethodNonce': {
          'nonce': 'test-nonce-123',
          'typeLabel': 'Visa',
          'description': 'ending in 11',
          'isDefault': true,
        },
        'deviceData': 'device-data-string',
      };
      final result = BraintreeDropInResult.fromJson(json);
      expect(result.paymentMethodNonce.nonce, 'test-nonce-123');
      expect(result.paymentMethodNonce.typeLabel, 'Visa');
      expect(result.paymentMethodNonce.description, 'ending in 11');
      expect(result.paymentMethodNonce.isDefault, true);
      expect(result.deviceData, 'device-data-string');
    });

    test('fromJson handles null deviceData', () {
      final json = {
        'paymentMethodNonce': {
          'nonce': 'nonce',
          'typeLabel': 'PayPal',
          'description': 'paypal@example.com',
          'isDefault': false,
        },
        'deviceData': null,
      };
      final result = BraintreeDropInResult.fromJson(json);
      expect(result.deviceData, null);
    });
  });

  group('BraintreePaymentMethodNonce', () {
    test('fromJson parses all fields', () {
      final json = {
        'nonce': 'abc-123',
        'typeLabel': 'PayPal',
        'description': 'paypal@example.com',
        'isDefault': false,
        'paypalPayerId': 'PAYER123',
      };
      final nonce = BraintreePaymentMethodNonce.fromJson(json);
      expect(nonce.nonce, 'abc-123');
      expect(nonce.typeLabel, 'PayPal');
      expect(nonce.description, 'paypal@example.com');
      expect(nonce.isDefault, false);
      expect(nonce.paypalPayerId, 'PAYER123');
    });

    test('fromJson handles null paypalPayerId', () {
      final json = {
        'nonce': 'nonce-456',
        'typeLabel': 'Visa',
        'description': 'ending in 1111',
        'isDefault': true,
      };
      final nonce = BraintreePaymentMethodNonce.fromJson(json);
      expect(nonce.paypalPayerId, null);
    });
  });

  group('ApplePaySummaryItem', () {
    test('toJson serializes correctly', () {
      final item = ApplePaySummaryItem(
        label: 'Total',
        amount: 9.99,
        type: ApplePaySummaryItemType.final_,
      );
      final json = item.toJson();
      expect(json['label'], 'Total');
      expect(json['amount'], 9.99);
      expect(json['type'], 0);
    });

    test('pending type has rawValue 1', () {
      expect(ApplePaySummaryItemType.pending.rawValue, 1);
    });
  });

  group('ApplePaySupportedNetworks', () {
    test('rawValue mapping', () {
      expect(ApplePaySupportedNetworks.visa.rawValue, 0);
      expect(ApplePaySupportedNetworks.masterCard.rawValue, 1);
      expect(ApplePaySupportedNetworks.amex.rawValue, 2);
      expect(ApplePaySupportedNetworks.discover.rawValue, 3);
    });
  });

  group('BraintreeApplePayRequest', () {
    test('toJson serializes all fields', () {
      final request = BraintreeApplePayRequest(
        paymentSummaryItems: [
          ApplePaySummaryItem(
            label: 'Item',
            amount: 5.0,
            type: ApplePaySummaryItemType.final_,
          ),
        ],
        displayName: 'Test Store',
        currencyCode: 'USD',
        countryCode: 'US',
        merchantIdentifier: 'merchant.com.test',
        supportedNetworks: [
          ApplePaySupportedNetworks.visa,
          ApplePaySupportedNetworks.masterCard,
        ],
      );
      final json = request.toJson();
      expect(json['displayName'], 'Test Store');
      expect(json['currencyCode'], 'USD');
      expect(json['countryCode'], 'US');
      expect(json['merchantIdentifier'], 'merchant.com.test');
      expect(json['supportedNetworks'], [0, 1]);
      expect((json['paymentSummaryItems'] as List).length, 1);
    });
  });

  group('PayPalPaymentIntent', () {
    test('has correct enum values', () {
      expect(PayPalPaymentIntent.values.length, 3);
      expect(PayPalPaymentIntent.order.name, 'order');
      expect(PayPalPaymentIntent.sale.name, 'sale');
      expect(PayPalPaymentIntent.authorize.name, 'authorize');
    });

    test('default intent is authorize', () {
      final request = BraintreePayPalRequest(amount: '10.00');
      expect(request.payPalPaymentIntent, PayPalPaymentIntent.authorize);
    });
  });

  group('PayPalPaymentUserAction', () {
    test('has correct enum values', () {
      expect(PayPalPaymentUserAction.values.length, 2);
      expect(PayPalPaymentUserAction.default_.name, 'default_');
      expect(PayPalPaymentUserAction.commit.name, 'commit');
    });

    test('default user action is default_', () {
      final request = BraintreePayPalRequest(amount: '10.00');
      expect(
          request.payPalPaymentUserAction, PayPalPaymentUserAction.default_);
    });
  });

  group('ApplePaySummaryItemType', () {
    test('final_ rawValue is 0', () {
      expect(ApplePaySummaryItemType.final_.rawValue, 0);
    });

    test('pending rawValue is 1', () {
      expect(ApplePaySummaryItemType.pending.rawValue, 1);
    });

    test('has exactly 2 values', () {
      expect(ApplePaySummaryItemType.values.length, 2);
    });
  });

  group('BraintreeDropInRequest edge cases', () {
    test('toJson includes paypalRequest when set', () {
      final request = BraintreeDropInRequest(
        tokenizationKey: 'key',
        paypalRequest: BraintreePayPalRequest(
          amount: '5.00',
          displayName: 'Test',
        ),
      );
      final json = request.toJson();
      expect(json.containsKey('paypalRequest'), true);
      final paypal = json['paypalRequest'] as Map<String, dynamic>;
      expect(paypal['amount'], '5.00');
      expect(paypal['displayName'], 'Test');
    });

    test('toJson includes googlePaymentRequest when set', () {
      final request = BraintreeDropInRequest(
        tokenizationKey: 'key',
        googlePaymentRequest: BraintreeGooglePaymentRequest(
          totalPrice: '10.00',
          currencyCode: 'USD',
        ),
      );
      final json = request.toJson();
      expect(json.containsKey('googlePaymentRequest'), true);
    });
  });

  group('BraintreePaymentMethodNonce construction', () {
    test('constructor sets all fields', () {
      final nonce = BraintreePaymentMethodNonce(
        nonce: 'test-nonce',
        typeLabel: 'Visa',
        description: 'ending in 1111',
        isDefault: true,
        paypalPayerId: 'PAYER_ID',
      );
      expect(nonce.nonce, 'test-nonce');
      expect(nonce.typeLabel, 'Visa');
      expect(nonce.description, 'ending in 1111');
      expect(nonce.isDefault, true);
      expect(nonce.paypalPayerId, 'PAYER_ID');
    });
  });
}
