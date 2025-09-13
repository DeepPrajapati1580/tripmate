// lib/services/razorpay_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Using cross-platform plugin that supports web+mobile:
// import 'package:razorpay_web/razorpay_web.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../config.dart';

class RazorpayService {
  static late Razorpay _razorpay;
  static BuildContext? _ctx;

  /// Call once (e.g. in initState) with a context so we can show SnackBars.
  static void init(BuildContext context) {
    _ctx = context;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Clear listeners when leaving the page
  static void dispose() {
    try {
      _razorpay.clear();
    } catch (_) {}
  }

  /// Optional: create an order on your server (recommended).
  /// Server should return order JSON from Razorpay orders.create(...)
  static Future<Map<String, dynamic>?> createOrder({
    required int amount, // rupees (e.g. 500)
    String currency = 'INR',
    String? receipt,
  }) async {
    if (SERVER_CREATE_ORDER_URL.isEmpty) {
      return null;
    }

    final uri = Uri.parse('${SERVER_CREATE_ORDER_URL}/create-order');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount, // rupees
        'currency': currency,
        'receipt': receipt,
      }),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Order creation failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Open Razorpay Checkout. `orderId` is optional (recommended to pass server order id).
  static Future<void> openCheckout({
    required int amount, // rupees
    String? orderId,
    String name = 'My App',
    String description = '',
    Map<String, String>? prefill,
  }) async {
    final options = {
      'key': 'rzp_test_RGhdz5pB4jl1PO',
      'amount': amount * 100, // paise
      'name': name,
      'description': description,
      if (orderId != null) 'order_id': orderId,
      'currency': 'INR',
      'prefill': prefill ?? {},
    };

    _razorpay.open(options);
  }

  // ------------ event handlers ------------
  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // response.paymentId, response.orderId, response.signature (if order was used)
    ScaffoldMessenger.of(_ctx!).showSnackBar(
      SnackBar(content: Text('Payment successful: ${response.paymentId}')),
    );

    // TODO: call your server's /verify-payment endpoint passing paymentId, orderId, signature
    // to confirm the signature using your secret (RECOMMENDED).
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(_ctx!).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(_ctx!).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }
}
