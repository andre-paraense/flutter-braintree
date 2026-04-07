import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../request.dart';
import '../result.dart';
import 'braintree_platform.dart';

/// Web implementation of [BraintreePlatform] using Braintree's JavaScript SDK.
///
/// This implementation uses `dart:js_interop` to communicate with the
/// Braintree Web Drop-in and Client JS SDKs loaded via `<script>` tags
/// in the web app's `index.html`.
///
/// Required scripts in `web/index.html`:
/// ```html
/// <script src="https://js.braintreegateway.com/web/dropin/1.43.0/js/dropin.min.js"></script>
/// <script src="https://js.braintreegateway.com/web/3.101.0/js/client.min.js"></script>
/// ```
class WebBraintreePlatform extends BraintreePlatform {
  @override
  Future<BraintreePaymentMethodNonce?> tokenizeCreditCard(
    String authorization,
    BraintreeCreditCardRequest request,
  ) async {
    _ensureBraintreeClientLoaded();

    final clientInstance = await _createClient(authorization);
    if (clientInstance == null) return null;

    try {
      final tokenizeOptions = _buildCreditCardTokenizeOptions(request);
      final result =
          await _tokenizeWithClient(clientInstance, tokenizeOptions);
      if (result == null) return null;
      return _parsePaymentMethodNonce(result);
    } finally {
      _teardownClient(clientInstance);
    }
  }

  @override
  Future<BraintreePaymentMethodNonce?> requestPaypalNonce(
    String authorization,
    BraintreePayPalRequest request,
  ) async {
    _ensureBraintreeClientLoaded();

    final clientInstance = await _createClient(authorization);
    if (clientInstance == null) return null;

    try {
      final paypalInstance =
          await _createPayPalCheckout(clientInstance);
      if (paypalInstance == null) return null;

      final paypalOptions = _buildPayPalOptions(request);
      final result =
          await _tokenizePayPal(paypalInstance, paypalOptions);
      if (result == null) return null;
      return _parsePaymentMethodNonce(result);
    } finally {
      _teardownClient(clientInstance);
    }
  }

  @override
  Future<BraintreeDropInResult?> startDropIn(
      BraintreeDropInRequest request) async {
    _ensureDropInLoaded();

    final authorization = request.clientToken ?? request.tokenizationKey;
    if (authorization == null) {
      throw ArgumentError(
          'Either clientToken or tokenizationKey must be provided.');
    }

    final overlay = _createOverlay();
    final container = _createDropInContainer();
    overlay.appendChild(container);
    web.document.body!.appendChild(overlay);

    try {
      final dropInOptions = _buildDropInOptions(authorization, request, container.id);
      final dropInInstance = await _createDropIn(dropInOptions);
      if (dropInInstance == null) {
        return null;
      }

      final result = await _requestDropInPayment(dropInInstance);
      if (result == null) return null;
      return _parseDropInResult(result, request.collectDeviceData);
    } finally {
      overlay.remove();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers: JS interop
  // ---------------------------------------------------------------------------

  /// Checks that the Braintree client JS SDK is loaded.
  void _ensureBraintreeClientLoaded() {
    final braintree = _globalBraintree;
    if (braintree == null) {
      throw StateError(
        'Braintree Web SDK not loaded. '
        'Add the following script tag to your web/index.html:\n'
        '<script src="https://js.braintreegateway.com/web/3.101.0/js/client.min.js"></script>',
      );
    }
  }

  /// Checks that the Braintree Drop-in JS SDK is loaded.
  void _ensureDropInLoaded() {
    final dropIn = _globalBraintreeDropin;
    if (dropIn == null) {
      throw StateError(
        'Braintree Drop-in SDK not loaded. '
        'Add the following script tag to your web/index.html:\n'
        '<script src="https://js.braintreegateway.com/web/dropin/1.43.0/js/dropin.min.js"></script>',
      );
    }
  }

  /// Creates a Braintree client instance.
  Future<JSObject?> _createClient(String authorization) async {
    final completer = Completer<JSObject?>();
    final options = _createJSObject();
    _setProperty(options, 'authorization', authorization.toJS);

    _callBraintreeClientCreate(
      options,
      ((JSAny? err, JSObject? client) {
        if (err != null) {
          completer.complete(null);
        } else {
          completer.complete(client);
        }
      }).toJS,
    );

    return completer.future;
  }

  /// Tokenizes credit card data using the Braintree client.
  Future<JSObject?> _tokenizeWithClient(
      JSObject client, JSObject options) async {
    final completer = Completer<JSObject?>();

    _callClientRequest(
      client,
      options,
      ((JSAny? err, JSObject? response) {
        if (err != null) {
          completer.complete(null);
        } else {
          completer.complete(response);
        }
      }).toJS,
    );

    return completer.future;
  }

  /// Creates a PayPal Checkout component.
  Future<JSObject?> _createPayPalCheckout(JSObject clientInstance) async {
    final paypalCheckout = _globalBraintreePaypalCheckout;
    if (paypalCheckout == null) return null;

    final completer = Completer<JSObject?>();
    final options = _createJSObject();
    _setProperty(options, 'client', clientInstance);

    _callPaypalCheckoutCreate(
      options,
      ((JSAny? err, JSObject? instance) {
        if (err != null) {
          completer.complete(null);
        } else {
          completer.complete(instance);
        }
      }).toJS,
    );

    return completer.future;
  }

  /// Tokenizes using PayPal Checkout.
  Future<JSObject?> _tokenizePayPal(
      JSObject paypalInstance, JSObject options) async {
    final completer = Completer<JSObject?>();

    _callPaypalTokenize(
      paypalInstance,
      options,
      ((JSAny? err, JSObject? payload) {
        if (err != null) {
          completer.complete(null);
        } else {
          completer.complete(payload);
        }
      }).toJS,
    );

    return completer.future;
  }

  /// Tears down a Braintree client instance.
  void _teardownClient(JSObject client) {
    _callTeardown(client, ((JSAny? err) {}).toJS);
  }

  /// Creates the Drop-in instance.
  Future<JSObject?> _createDropIn(JSObject options) async {
    final completer = Completer<JSObject?>();

    _callDropinCreate(
      options,
      ((JSAny? err, JSObject? instance) {
        if (err != null) {
          completer.complete(null);
        } else {
          completer.complete(instance);
        }
      }).toJS,
    );

    return completer.future;
  }

  /// Requests payment from a Drop-in instance.
  /// Returns a [Future] that resolves when the user completes or cancels payment.
  Future<JSObject?> _requestDropInPayment(JSObject dropInInstance) async {
    final completer = Completer<JSObject?>();

    _callDropinRequestPayment(
      dropInInstance,
      ((JSAny? err, JSObject? payload) {
        if (err != null) {
          completer.complete(null);
        } else {
          completer.complete(payload);
        }
      }).toJS,
    );

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // Private helpers: Option builders
  // ---------------------------------------------------------------------------

  /// Builds the credit card tokenization options for the Braintree client.
  JSObject _buildCreditCardTokenizeOptions(BraintreeCreditCardRequest request) {
    final data = _createJSObject();
    _setProperty(data, 'number', request.cardNumber.toJS);
    _setProperty(data, 'expirationMonth', request.expirationMonth.toJS);
    _setProperty(data, 'expirationYear', request.expirationYear.toJS);
    _setProperty(data, 'cvv', request.cvv.toJS);
    if (request.cardholderName != null) {
      _setProperty(data, 'cardholderName', request.cardholderName!.toJS);
    }

    final creditCard = _createJSObject();
    _setProperty(creditCard, 'creditCard', data);

    final options = _createJSObject();
    _setProperty(options, 'endpoint', 'payment_methods/credit_cards'.toJS);
    _setProperty(options, 'method', 'post'.toJS);
    _setProperty(options, 'data', creditCard);

    return options;
  }

  /// Builds PayPal tokenization options.
  JSObject _buildPayPalOptions(BraintreePayPalRequest request) {
    final options = _createJSObject();
    if (request.amount != null) {
      _setProperty(options, 'flow', 'checkout'.toJS);
      _setProperty(options, 'amount', request.amount!.toJS);
    } else {
      _setProperty(options, 'flow', 'vault'.toJS);
    }
    if (request.currencyCode != null) {
      _setProperty(options, 'currency', request.currencyCode!.toJS);
    }
    if (request.displayName != null) {
      _setProperty(options, 'displayName', request.displayName!.toJS);
    }
    if (request.billingAgreementDescription != null) {
      _setProperty(options, 'billingAgreementDescription',
          request.billingAgreementDescription!.toJS);
    }
    return options;
  }

  /// Builds options for creating the Drop-in UI.
  JSObject _buildDropInOptions(
    String authorization,
    BraintreeDropInRequest request,
    String containerId,
  ) {
    final options = _createJSObject();
    _setProperty(options, 'authorization', authorization.toJS);
    _setProperty(options, 'container', '#$containerId'.toJS);

    if (request.paypalRequest != null) {
      final paypal = _createJSObject();
      _setProperty(paypal, 'flow',
          request.paypalRequest!.amount != null ? 'checkout'.toJS : 'vault'.toJS);
      if (request.paypalRequest!.amount != null) {
        _setProperty(paypal, 'amount', request.paypalRequest!.amount!.toJS);
      }
      if (request.paypalRequest!.currencyCode != null) {
        _setProperty(
            paypal, 'currency', request.paypalRequest!.currencyCode!.toJS);
      }
      _setProperty(options, 'paypal', paypal);
    }

    if (!request.cardEnabled) {
      _setProperty(options, 'card', false.toJS);
    }

    if (request.requestThreeDSecureVerification && request.amount != null) {
      final threeDSecure = _createJSObject();
      _setProperty(threeDSecure, 'amount', request.amount!.toJS);
      _setProperty(options, 'threeDSecure', threeDSecure);
    }

    return options;
  }

  // ---------------------------------------------------------------------------
  // Private helpers: Result parsers
  // ---------------------------------------------------------------------------

  /// Parses a JS payment method nonce result into a [BraintreePaymentMethodNonce].
  BraintreePaymentMethodNonce _parsePaymentMethodNonce(JSObject result) {
    final nonce = _getStringProperty(result, 'nonce') ?? '';
    final type = _getStringProperty(result, 'type') ?? '';
    final description = _getStringProperty(result, 'description') ?? '';

    // Check for PayPal-specific details
    String? paypalPayerId;
    final details = _getProperty(result, 'details');
    if (details != null) {
      paypalPayerId = _getStringProperty(details as JSObject, 'payerId');
    }

    return BraintreePaymentMethodNonce(
      nonce: nonce,
      typeLabel: type,
      description: description,
      isDefault: false,
      paypalPayerId: paypalPayerId,
    );
  }

  /// Parses a Drop-in result into a [BraintreeDropInResult].
  BraintreeDropInResult _parseDropInResult(
      JSObject result, bool collectDeviceData) {
    final nonce = _parsePaymentMethodNonce(result);
    final deviceData = collectDeviceData
        ? _getStringProperty(result, 'deviceData')
        : null;

    return BraintreeDropInResult(
      paymentMethodNonce: nonce,
      deviceData: deviceData,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers: DOM manipulation
  // ---------------------------------------------------------------------------

  /// Creates a semi-transparent overlay element for the Drop-in UI.
  web.HTMLDivElement _createOverlay() {
    final overlay = web.document.createElement('div') as web.HTMLDivElement;
    overlay.id = 'braintree-dropin-overlay';
    overlay.style.position = 'fixed';
    overlay.style.top = '0';
    overlay.style.left = '0';
    overlay.style.width = '100%';
    overlay.style.height = '100%';
    overlay.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
    overlay.style.zIndex = '9999';
    overlay.style.display = 'flex';
    overlay.style.justifyContent = 'center';
    overlay.style.alignItems = 'center';
    return overlay;
  }

  /// Creates the container element for the Drop-in UI.
  web.HTMLDivElement _createDropInContainer() {
    final container = web.document.createElement('div') as web.HTMLDivElement;
    container.id = 'braintree-dropin-container';
    container.style.backgroundColor = 'white';
    container.style.borderRadius = '8px';
    container.style.padding = '24px';
    container.style.maxWidth = '400px';
    container.style.width = '100%';
    container.style.maxHeight = '80vh';
    container.style.overflowY = 'auto';
    return container;
  }
}

// =============================================================================
// JS Interop bindings for Braintree Web SDKs
// =============================================================================

/// Access the global `braintree` object.
JSObject? get _globalBraintree {
  final braintree = _getGlobalProperty('braintree');
  return braintree as JSObject?;
}

/// Access the global `braintree.dropin` object.
JSObject? get _globalBraintreeDropin {
  final braintree = _globalBraintree;
  if (braintree == null) return null;
  return _getProperty(braintree, 'dropin') as JSObject?;
}

/// Access the global `braintree.paypalCheckout` object.
JSObject? get _globalBraintreePaypalCheckout {
  final braintree = _globalBraintree;
  if (braintree == null) return null;
  return _getProperty(braintree, 'paypalCheckout') as JSObject?;
}

// Helper functions for JS interop

JSObject _createJSObject() {
  return _jsNewObject();
}

@JS('Object.create')
external JSObject _jsObjectCreate(JSAny? proto);

JSObject _jsNewObject() => _jsObjectCreate(null);

void _setProperty(JSObject obj, String key, JSAny? value) {
  _jsSetProperty(obj, key.toJS, value);
}

@JS('Reflect.set')
external void _jsSetProperty(JSObject target, JSAny key, JSAny? value);

JSAny? _getProperty(JSObject obj, String key) {
  return _jsGetProperty(obj, key.toJS);
}

@JS('Reflect.get')
external JSAny? _jsGetProperty(JSObject target, JSAny key);

JSAny? _getGlobalProperty(String key) {
  return _jsGetProperty(_globalThis, key.toJS);
}

@JS('globalThis')
external JSObject get _globalThis;

String? _getStringProperty(JSObject obj, String key) {
  final value = _getProperty(obj, key);
  if (value == null) return null;
  if (value.isA<JSString>()) {
    return (value as JSString).toDart;
  }
  return null;
}

// Braintree client create
void _callBraintreeClientCreate(JSObject options, JSFunction callback) {
  final braintree = _globalBraintree!;
  final client = _getProperty(braintree, 'client') as JSObject;
  final create = _getProperty(client, 'create') as JSFunction;
  create.callAsFunction(client, options, callback);
}

// Braintree client request (for tokenization)
void _callClientRequest(
    JSObject client, JSObject options, JSFunction callback) {
  final request = _getProperty(client, 'request') as JSFunction;
  request.callAsFunction(client, options, callback);
}

// Braintree PayPal Checkout create
void _callPaypalCheckoutCreate(JSObject options, JSFunction callback) {
  final paypalCheckout = _globalBraintreePaypalCheckout!;
  final create = _getProperty(paypalCheckout, 'create') as JSFunction;
  create.callAsFunction(paypalCheckout, options, callback);
}

// Braintree PayPal Checkout tokenize
void _callPaypalTokenize(
    JSObject instance, JSObject options, JSFunction callback) {
  final tokenize = _getProperty(instance, 'tokenizePayment') as JSFunction;
  tokenize.callAsFunction(instance, options, callback);
}

// Braintree client teardown
void _callTeardown(JSObject client, JSFunction callback) {
  final teardown = _getProperty(client, 'teardown') as JSFunction;
  teardown.callAsFunction(client, callback);
}

// Braintree Drop-in create
void _callDropinCreate(JSObject options, JSFunction callback) {
  final dropin = _globalBraintreeDropin!;
  final create = _getProperty(dropin, 'create') as JSFunction;
  create.callAsFunction(dropin, options, callback);
}

// Braintree Drop-in requestPaymentMethod
void _callDropinRequestPayment(JSObject instance, JSFunction callback) {
  final requestPayment =
      _getProperty(instance, 'requestPaymentMethod') as JSFunction;
  requestPayment.callAsFunction(instance, callback);
}
