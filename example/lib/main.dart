import 'package:flutter/foundation.dart';
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

  void showError(Object error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(error.toString()),
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
            ElevatedButton(
              onPressed: () async {
                try {
                  var request = BraintreeDropInRequest(
                    tokenizationKey: tokenizationKey,
                    collectDeviceData: true,
                    vaultManagerEnabled: kIsWeb ? false : true,
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
                    paypalRequest: BraintreePayPalRequest(
                      amount: '4.20',
                      displayName: 'Example company',
                    ),
                    cardEnabled: true,
                  );
                  final result = await BraintreeDropIn.start(request);
                  if (!mounted) return;
                  if (result != null) {
                    showNonce(result.paymentMethodNonce);
                  }
                } catch (e) {
                  if (!mounted) return;
                  showError(e);
                }
              },
              child: Text('LAUNCH DROP-IN'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final request = BraintreeCreditCardRequest(
                    cardNumber: '4111111111111111',
                    expirationMonth: '12',
                    expirationYear: (DateTime.now().year + 1).toString(),
                    cvv: '123',
                  );
                  final result = await Braintree.tokenizeCreditCard(
                    tokenizationKey,
                    request,
                  );
                  if (!mounted) return;
                  if (result != null) {
                    showNonce(result);
                  }
                } catch (e) {
                  if (!mounted) return;
                  showError(e);
                }
              },
              child: Text('TOKENIZE CREDIT CARD'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final request = BraintreePayPalRequest(
                    amount: null,
                    billingAgreementDescription:
                        'I hereby agree that flutter_braintree is great.',
                    displayName: 'Your Company',
                  );
                  final result = await Braintree.requestPaypalNonce(
                    tokenizationKey,
                    request,
                  );
                  if (!mounted) return;
                  if (result != null) {
                    showNonce(result);
                  }
                } catch (e) {
                  if (!mounted) return;
                  showError(e);
                }
              },
              child: Text('PAYPAL VAULT FLOW'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final request = BraintreePayPalRequest(amount: '13.37');
                  final result = await Braintree.requestPaypalNonce(
                    tokenizationKey,
                    request,
                  );
                  if (!mounted) return;
                  if (result != null) {
                    showNonce(result);
                  }
                } catch (e) {
                  if (!mounted) return;
                  showError(e);
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
