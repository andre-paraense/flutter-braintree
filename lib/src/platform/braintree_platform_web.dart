@JS()
library flutter_braintree_platform_web;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../request.dart';
import '../result.dart';
import 'braintree_platform.dart';

// ---------------------------------------------------------------------------
// Minimal DOM interop (avoids package:web dependency)
// ---------------------------------------------------------------------------

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Element createElement(String tagName);
  external _Element? getElementById(String elementId);
  external _Element? get body;
  external _Element? get head;
}

extension type _Element._(JSObject _) implements JSObject {
  external set id(String value);
  external set className(String value);
  external set textContent(String value);
  external set innerHTML(String value);
  external _CSSStyleDeclaration get style;
  external void appendChild(_Element child);
  external void remove();
  external void addEventListener(String type, JSFunction callback);
  external set src(String value);
  external set type(String value);
  @JS('onload')
  external set onload(JSFunction? value);
  @JS('onerror')
  external set onerror(JSFunction? value);
}

extension type _CSSStyleDeclaration._(JSObject _) implements JSObject {
  external set position(String value);
  external set top(String value);
  external set left(String value);
  external set right(String value);
  external set bottom(String value);
  external set width(String value);
  external set height(String value);
  external set display(String value);
  external set backgroundColor(String value);
  external set zIndex(String value);
  external set overflow(String value);
  external set overflowY(String value);
  external set padding(String value);
  external set margin(String value);
  external set border(String value);
  external set borderRadius(String value);
  external set cursor(String value);
  external set color(String value);
  external set fontSize(String value);
  external set fontWeight(String value);
  external set textAlign(String value);
  external set maxWidth(String value);
  external set boxSizing(String value);
  external set justifyContent(String value);
  external set alignItems(String value);
  external set gap(String value);
  external set flexDirection(String value);
  external set fontFamily(String value);
  external set boxShadow(String value);
  external set maxHeight(String value);
}

// ---------------------------------------------------------------------------
// Braintree JS SDK interop
// ---------------------------------------------------------------------------

/// braintree.dropin.create(options) → Promise<DropinInstance>
@JS('braintree.dropin.create')
external JSPromise<_DropinInstance> _dropinCreate(JSObject options);

/// braintree.client.create(options) → Promise<ClientInstance>
@JS('braintree.client.create')
external JSPromise<_ClientInstance> _clientCreate(JSObject options);

/// braintree.paypalCheckout.create(options) → Promise<PayPalCheckoutInstance>
@JS('braintree.paypalCheckout.create')
external JSPromise<_PayPalCheckoutInstance> _paypalCheckoutCreate(
    JSObject options);

/// paypal.Buttons(config) → PayPalButtonsInstance
@JS('paypal.Buttons')
external _PayPalButtonsInstance _paypalButtons(JSObject config);

/// Dropin instance returned from braintree.dropin.create
extension type _DropinInstance._(JSObject _) implements JSObject {
  external JSPromise<JSObject> requestPaymentMethod();
  external JSPromise teardown();
}

/// Client instance returned from braintree.client.create
extension type _ClientInstance._(JSObject _) implements JSObject {
  external JSPromise<JSObject> request(JSObject options);
}

/// PayPal Checkout instance returned from braintree.paypalCheckout.create
extension type _PayPalCheckoutInstance._(JSObject _) implements JSObject {
  external JSPromise<JSObject> createPayment(JSObject options);
  external JSPromise<JSObject> tokenizePayment(JSObject data);
  external JSPromise loadPayPalSDK(JSObject options);
}

/// PayPal Buttons instance returned from paypal.Buttons()
extension type _PayPalButtonsInstance._(JSObject _) implements JSObject {
  external JSPromise render(String selector);
}

// ---------------------------------------------------------------------------
// Script loader
// ---------------------------------------------------------------------------

const _dropinSdkUrl =
    'https://js.braintreegateway.com/web/dropin/1.43.0/js/dropin.min.js';
const _clientSdkUrl =
    'https://js.braintreegateway.com/web/3.101.0/js/client.min.js';
const _paypalCheckoutSdkUrl =
    'https://js.braintreegateway.com/web/3.101.0/js/paypal-checkout.min.js';

Future<void> _loadScript(String url) {
  final completer = Completer<void>();
  final script = _document.createElement('script');
  script.src = url;
  script.type = 'text/javascript';
  script.onload = (() {
    completer.complete();
  }).toJS;
  script.onerror = ((JSAny error) {
    completer.completeError('Failed to load script: $url');
  }).toJS;
  _document.head!.appendChild(script);
  return completer.future;
}

/// Checks whether a nested JS property path exists on the global context.
/// For example, `_jsExists('braintree.dropin')` checks that
/// `globalContext.braintree.dropin` is defined and non-null.
bool _jsExists(String path) {
  JSAny? current = globalContext;
  for (final part in path.split('.')) {
    if (current == null || current is! JSObject) return false;
    current = current[part];
  }
  return current != null;
}

Future<void> _ensureDropinLoaded() async {
  if (!_jsExists('braintree.dropin')) {
    await _loadScript(_dropinSdkUrl);
  }
}

Future<void> _ensureClientLoaded() async {
  if (!_jsExists('braintree.client')) {
    await _loadScript(_clientSdkUrl);
  }
}

Future<void> _ensurePayPalCheckoutLoaded() async {
  if (!_jsExists('braintree.paypalCheckout')) {
    await _loadScript(_paypalCheckoutSdkUrl);
  }
}

// ---------------------------------------------------------------------------
// Helper: build a JSObject from a Dart Map
// ---------------------------------------------------------------------------

JSObject _jsObject(Map<String, Object?> map) => map.jsify() as JSObject;

// ---------------------------------------------------------------------------
// Web platform implementation
// ---------------------------------------------------------------------------

class BraintreePlatformWeb extends BraintreePlatform {
  @override
  Future<BraintreeDropInResult?> startDropIn(
      BraintreeDropInRequest request) async {
    await _ensureDropinLoaded();

    final authorization = request.clientToken ?? request.tokenizationKey;
    if (authorization == null) {
      throw Exception(
          'Either clientToken or tokenizationKey must be provided.');
    }

    // Build options for braintree.dropin.create
    final options = <String, Object?>{
      'authorization': authorization,
    };

    // PayPal configuration
    if (request.paypalEnabled && request.paypalRequest != null) {
      final pr = request.paypalRequest!;
      options['paypal'] = <String, Object?>{
        'flow': pr.amount != null ? 'checkout' : 'vault',
        if (pr.amount != null) 'amount': pr.amount,
        if (pr.currencyCode != null) 'currency': pr.currencyCode,
        if (pr.displayName != null) 'displayName': pr.displayName,
        if (pr.billingAgreementDescription != null)
          'billingAgreementDescription': pr.billingAgreementDescription,
      };
    }

    // Card configuration
    if (!request.cardEnabled) {
      options['card'] = false;
    }

    // The completer that resolves when the user submits or cancels
    final completer = Completer<BraintreeDropInResult?>();

    // --- Build the overlay DOM ---
    if (_document.getElementById('braintree-dropin-overlay') != null) {
      throw StateError(
        'Braintree drop-in is already open: overlay element '
        '"braintree-dropin-overlay" already exists.',
      );
    }

    final overlay = _document.createElement('div');
    overlay.id = 'braintree-dropin-overlay';
    overlay.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = 'rgba(0,0,0,0.5)'
      ..zIndex = '99999'
      ..display = 'flex'
      ..justifyContent = 'center'
      ..alignItems = 'center'
      ..fontFamily =
          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

    final dialog = _document.createElement('div');
    dialog.style
      ..backgroundColor = '#ffffff'
      ..borderRadius = '12px'
      ..padding = '24px'
      ..maxWidth = '400px'
      ..width = '90%'
      ..maxHeight = '80vh'
      ..overflowY = 'auto'
      ..boxSizing = 'border-box'
      ..boxShadow = '0 4px 24px rgba(0,0,0,0.2)';

    final title = _document.createElement('h2');
    title.textContent = 'Payment';
    title.style
      ..margin = '0 0 16px 0'
      ..textAlign = 'center'
      ..fontSize = '20px'
      ..color = '#333333';

    final containerId =
        'braintree-dropin-container-${DateTime.now().microsecondsSinceEpoch}';
    final container = _document.createElement('div');
    container.id = containerId;

    final buttonRow = _document.createElement('div');
    buttonRow.style
      ..display = 'flex'
      ..justifyContent = 'center'
      ..gap = '12px'
      ..margin = '16px 0 0 0';

    final submitBtn = _document.createElement('button');
    submitBtn.textContent = 'Submit Payment';
    submitBtn.style
      ..padding = '10px 24px'
      ..fontSize = '16px'
      ..fontWeight = '600'
      ..backgroundColor = '#0070ba'
      ..color = '#ffffff'
      ..border = 'none'
      ..borderRadius = '6px'
      ..cursor = 'pointer';

    final cancelBtn = _document.createElement('button');
    cancelBtn.textContent = 'Cancel';
    cancelBtn.style
      ..padding = '10px 24px'
      ..fontSize = '16px'
      ..fontWeight = '600'
      ..backgroundColor = '#e0e0e0'
      ..color = '#333333'
      ..border = 'none'
      ..borderRadius = '6px'
      ..cursor = 'pointer';

    buttonRow.appendChild(submitBtn);
    buttonRow.appendChild(cancelBtn);
    dialog.appendChild(title);
    dialog.appendChild(container);
    dialog.appendChild(buttonRow);
    overlay.appendChild(dialog);
    _document.body!.appendChild(overlay);

    // Set the container element for the Drop-in to render into
    options['container'] = '#$containerId';

    _DropinInstance? instance;
    var isSubmitting = false;

    void cleanup() {
      isSubmitting = false;
      final currentInstance = instance;
      instance = null;

      if (currentInstance != null) {
        unawaited(
          currentInstance.teardown().toDart.catchError((Object _) {
            // Ignore teardown failures during cleanup.
            return null;
          }),
        );
      }
      overlay.remove();
    }

    try {
      instance = await _dropinCreate(_jsObject(options)).toDart;
    } catch (e) {
      cleanup();
      throw Exception('Failed to create Braintree Drop-in: $e');
    }

    // Handle cancel
    cancelBtn.addEventListener(
      'click',
      (() {
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }).toJS,
    );

    // Handle submit
    submitBtn.addEventListener(
      'click',
      (() {
        if (isSubmitting) return;
        isSubmitting = true;
        _handleDropInSubmit(instance!, completer, cleanup);
      }).toJS,
    );

    return completer.future;
  }

  @override
  Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  ) async {
    await _ensureClientLoaded();

    final clientInstance =
        await _clientCreate(_jsObject({'authorization': authorization})).toDart;

    final expirationDate =
        '${request.expirationMonth}/${request.expirationYear}';
    final creditCard = <String, Object?>{
      'number': request.cardNumber,
      'expirationDate': expirationDate,
      'cvv': request.cvv,
      if (request.cardholderName != null)
        'cardholderName': request.cardholderName,
    };

    final response = await clientInstance
        .request(_jsObject({
          'endpoint': 'payment_methods/credit_cards',
          'method': 'post',
          'data': {
            'creditCard': creditCard,
          },
        }))
        .toDart;

    // The response contains creditCards array
    final creditCards = response['creditCards'];
    if (creditCards == null || creditCards is! JSArray) return null;
    if (creditCards.length == 0) return null;

    final firstCardValue = creditCards[0];
    if (firstCardValue is! JSObject) return null;

    final firstCard = firstCardValue;
    final nonce = (firstCard['nonce'] as JSString?)?.toDart;
    if (nonce == null || nonce.isEmpty) return null;

    final typeLabel =
        (firstCard['type'] as JSString?)?.toDart ?? 'CreditCard';
    final description =
        (firstCard['description'] as JSString?)?.toDart ?? '';

    return BraintreePaymentMethodNonce(
      nonce: nonce,
      typeLabel: typeLabel,
      description: description,
      isDefault: false,
    );
  }

  @override
  Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  ) async {
    await _ensureClientLoaded();
    await _ensurePayPalCheckoutLoaded();

    final clientInstance =
        await _clientCreate(_jsObject({'authorization': authorization})).toDart;

    final paypalInstance = await _paypalCheckoutCreate(
      _jsObject({'client': clientInstance}),
    ).toDart;

    final isVault = request.amount == null;

    // Load the PayPal SDK
    await paypalInstance
        .loadPayPalSDK(
          _jsObject({
            if (isVault) 'vault': true,
            if (!isVault) 'intent': request.payPalPaymentIntent.name,
          }),
        )
        .toDart;

    // Build the overlay with a PayPal button container
    final completer = Completer<BraintreePaymentMethodNonce?>();

    if (_document.getElementById('braintree-paypal-overlay') != null) {
      throw StateError(
        'Braintree PayPal flow is already open: overlay element '
        '"braintree-paypal-overlay" already exists.',
      );
    }

    final overlay = _document.createElement('div');
    overlay.id = 'braintree-paypal-overlay';
    overlay.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = 'rgba(0,0,0,0.5)'
      ..zIndex = '99999'
      ..display = 'flex'
      ..justifyContent = 'center'
      ..alignItems = 'center'
      ..fontFamily =
          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

    final dialog = _document.createElement('div');
    dialog.style
      ..backgroundColor = '#ffffff'
      ..borderRadius = '12px'
      ..padding = '24px'
      ..maxWidth = '400px'
      ..width = '90%'
      ..boxSizing = 'border-box'
      ..boxShadow = '0 4px 24px rgba(0,0,0,0.2)';

    final titleEl = _document.createElement('h2');
    titleEl.textContent = 'PayPal';
    titleEl.style
      ..margin = '0 0 16px 0'
      ..textAlign = 'center'
      ..fontSize = '20px'
      ..color = '#333333';

    final paypalContainerId =
        'braintree-paypal-button-container-${DateTime.now().microsecondsSinceEpoch}';
    final paypalContainer = _document.createElement('div');
    paypalContainer.id = paypalContainerId;

    final cancelBtn = _document.createElement('button');
    cancelBtn.textContent = 'Cancel';
    cancelBtn.style
      ..display = 'block'
      ..width = '100%'
      ..padding = '10px 24px'
      ..margin = '16px 0 0 0'
      ..fontSize = '16px'
      ..fontWeight = '600'
      ..backgroundColor = '#e0e0e0'
      ..color = '#333333'
      ..border = 'none'
      ..borderRadius = '6px'
      ..cursor = 'pointer'
      ..textAlign = 'center';

    cancelBtn.addEventListener(
      'click',
      (() {
        overlay.remove();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }).toJS,
    );

    dialog.appendChild(titleEl);
    dialog.appendChild(paypalContainer);
    dialog.appendChild(cancelBtn);
    overlay.appendChild(dialog);
    _document.body!.appendChild(overlay);

    // Render PayPal buttons via the global `paypal` object
    try {
      final paymentOptions = <String, Object?>{
        'flow': isVault ? 'vault' : 'checkout',
        if (!isVault) 'amount': request.amount,
        if (request.currencyCode != null) 'currency': request.currencyCode,
        if (isVault && request.billingAgreementDescription != null)
          'billingAgreementDescription': request.billingAgreementDescription,
        if (!isVault) 'intent': request.payPalPaymentIntent.name,
      };

      final buttonsConfig = <String, Object?>{};

      if (isVault) {
        buttonsConfig['createBillingAgreement'] = (() {
          return paypalInstance.createPayment(_jsObject(paymentOptions));
        }).toJS;
      } else {
        buttonsConfig['createOrder'] = (() {
          return paypalInstance.createPayment(_jsObject(paymentOptions));
        }).toJS;
      }

      buttonsConfig['onApprove'] = ((JSObject data) {
        _handlePayPalApprove(data, paypalInstance, overlay, completer);
      }).toJS;

      buttonsConfig['onCancel'] = (() {
        overlay.remove();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }).toJS;

      buttonsConfig['onError'] = ((JSAny err) {
        overlay.remove();
        if (!completer.isCompleted) {
          completer.completeError('PayPal error: $err');
        }
      }).toJS;

      // Create and render PayPal buttons using direct JS interop
      final buttons = _paypalButtons(buttonsConfig.jsify() as JSObject);
      await buttons.render('#$paypalContainerId').toDart;
    } catch (e) {
      overlay.remove();
      if (!completer.isCompleted) {
        completer.completeError('Failed to render PayPal buttons: $e');
      }
    }

    return completer.future;
  }

  /// Async handler for Drop-in submit, extracted so the JS callback stays sync.
  Future<void> _handleDropInSubmit(
    _DropinInstance instance,
    Completer<BraintreeDropInResult?> completer,
    void Function() cleanup,
  ) async {
    try {
      final payload = await instance.requestPaymentMethod().toDart;
      final nonce = (payload['nonce'] as JSString?)?.toDart ?? '';
      final typeLabel = (payload['type'] as JSString?)?.toDart ?? '';
      final description =
          (payload['description'] as JSString?)?.toDart ?? '';

      String? paypalPayerId;
      final details = payload['details'];
      if (details != null && details is JSObject) {
        final payerIdJs = details['payerId'];
        if (payerIdJs != null && payerIdJs is JSString) {
          paypalPayerId = payerIdJs.toDart;
        }
      }

      cleanup();
      if (!completer.isCompleted) {
        completer.complete(BraintreeDropInResult(
          paymentMethodNonce: BraintreePaymentMethodNonce(
            nonce: nonce,
            typeLabel: typeLabel,
            description: description,
            isDefault: false,
            paypalPayerId: paypalPayerId,
          ),
          deviceData: null,
        ));
      }
    } catch (e, st) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    }
  }

  /// Async handler for PayPal onApprove, extracted so the JS callback stays sync.
  Future<void> _handlePayPalApprove(
    JSObject data,
    _PayPalCheckoutInstance paypalInstance,
    _Element overlay,
    Completer<BraintreePaymentMethodNonce?> completer,
  ) async {
    try {
      final payload = await paypalInstance.tokenizePayment(data).toDart;
      final nonce = (payload['nonce'] as JSString?)?.toDart ?? '';
      final typeLabel = 'PayPal';

      String? payerId;
      final details = payload['details'];
      if (details != null && details is JSObject) {
        final payerIdJs = details['payerId'];
        if (payerIdJs != null && payerIdJs is JSString) {
          payerId = payerIdJs.toDart;
        }
      }

      overlay.remove();
      if (!completer.isCompleted) {
        completer.complete(BraintreePaymentMethodNonce(
          nonce: nonce,
          typeLabel: typeLabel,
          description: 'PayPal',
          isDefault: false,
          paypalPayerId: payerId,
        ));
      }
    } catch (e) {
      overlay.remove();
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  }
}

BraintreePlatform createPlatform() => BraintreePlatformWeb();
