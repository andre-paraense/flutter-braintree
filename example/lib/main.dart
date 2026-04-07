import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_braintree/flutter_braintree.dart';

void main() => runApp(
      MaterialApp(
        home: MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final String tokenizationKey = 'sandbox_8hxpnkht_kzdtzv2btm4p7s5j';

  void showNonce(BraintreePaymentMethodNonce nonce) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Payment method nonce:'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Nonce: ${nonce.nonce}'),
            SizedBox(height: 16),
            Text('Type label: ${nonce.typeLabel}'),
            SizedBox(height: 16),
            Text('Description: ${nonce.description}'),
          ],
        ),
      ),
    );
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braintree example app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Running on Web',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                var request = BraintreeDropInRequest(
                  tokenizationKey: tokenizationKey,
                  collectDeviceData: true,
                  requestThreeDSecureVerification: true,
                  email: "test@email.com",
                  billingAddress: BraintreeBillingAddress(
                    givenName: "Jill",
                    surname: "Doe",
                    phoneNumber: "5551234567",
                    streetAddress: "555 Smith St",
                    extendedAddress: "#2",
                    locality: "Chicago",
                    region: "IL",
                    postalCode: "12345",
                    countryCodeAlpha2: "US",
                  ),
                  paypalRequest: BraintreePayPalRequest(
                    amount: '4.20',
                    displayName: 'Example company',
                  ),
                  cardEnabled: true,
                  // Google Pay and Apple Pay are not available on web
                  googlePaymentRequest: kIsWeb
                      ? null
                      : BraintreeGooglePaymentRequest(
                          totalPrice: '4.20',
                          currencyCode: 'USD',
                          billingAddressRequired: false,
                        ),
                  applePayRequest: kIsWeb
                      ? null
                      : BraintreeApplePayRequest(
                          currencyCode: 'USD',
                          supportedNetworks: [
                            ApplePaySupportedNetworks.visa,
                            ApplePaySupportedNetworks.masterCard,
                          ],
                          countryCode: 'US',
                          merchantIdentifier: '',
                          displayName: '',
                          paymentSummaryItems: [],
                        ),
                  vaultManagerEnabled: !kIsWeb,
                );
                try {
                  final result = await BraintreeDropIn.start(request);
                  if (result != null) {
                    showNonce(result.paymentMethodNonce);
                  }
                } catch (e) {
                  showError(e.toString());
                }
              },
              child: Text('LAUNCH DROP-IN'),
            ),
            ElevatedButton(
              onPressed: () async {
                final request = BraintreeCreditCardRequest(
                  cardNumber: '4111111111111111',
                  expirationMonth: '12',
                  expirationYear: '2021',
                  cvv: '123',
                );
                try {
                  final result = await Braintree.tokenizeCreditCard(
                    tokenizationKey,
                    request,
                  );
                  if (result != null) {
                    showNonce(result);
                  }
                } catch (e) {
                  showError(e.toString());
                }
              },
              child: Text('TOKENIZE CREDIT CARD'),
            ),
            ElevatedButton(
              onPressed: () async {
                final request = BraintreePayPalRequest(
                  amount: null,
                  billingAgreementDescription:
                      'I hereby agree that flutter_braintree is great.',
                  displayName: 'Your Company',
                );
                try {
                  final result = await Braintree.requestPaypalNonce(
                    tokenizationKey,
                    request,
                  );
                  if (result != null) {
                    showNonce(result);
                  }
                } catch (e) {
                  showError(e.toString());
                }
              },
              child: Text('PAYPAL VAULT FLOW'),
            ),
            ElevatedButton(
              onPressed: () async {
                final request = BraintreePayPalRequest(amount: '13.37');
                try {
                  final result = await Braintree.requestPaypalNonce(
                    tokenizationKey,
                    request,
                  );
                  if (result != null) {
                    showNonce(result);
                  }
                } catch (e) {
                  showError(e.toString());
                }
              },
              child: Text('PAYPAL CHECKOUT FLOW'),
            ),
          ],
        ),
      ),
    );
  }
}
