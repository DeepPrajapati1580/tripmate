// lib/services/razorpay_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config.dart';
import '../services/booking_service.dart';

class RazorpayService {
  static late Razorpay _razorpay;
  static BuildContext? _ctx;
  static String? _currentBookingId;

  /// Call once from the page (initState) with context
  static void init(BuildContext ctx) {
    _ctx = ctx;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Create Order on your server (server uses Razorpay secret)
  static Future<Map<String, dynamic>> createOrderOnServer({
    required int amountInPaise,
    required String bookingId,
  }) async {
    final url = Uri.parse('$SERVER_CREATE_ORDER_URL/create_order');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amountInPaise, 'currency': 'INR', 'receipt': bookingId}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to create order: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Open checkout (store bookingId so success handler can use it)
  static void openCheckout({
    required String orderId,
    required int amountInPaise,
    required String bookingId,
    String? prefillContact,
    String? prefillEmail,
  }) {
    _currentBookingId = bookingId;
    final options = {
      'key': RAZORPAY_KEY_ID,
      'amount': amountInPaise,
      'order_id': orderId,
      'name': 'TripMate',
      'description': 'Trip booking',
      'prefill': {'contact': prefillContact ?? '', 'email': prefillEmail ?? ''},
      'theme': {'color': '#0f9d58'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (_ctx != null) {
        ScaffoldMessenger.of(_ctx!).showSnackBar(SnackBar(content: Text('Could not open payment: $e')));
      }
    }
  }

  static void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // response.orderId, response.paymentId, response.signature
    if (_ctx == null) return;
    try {
      final verifyUrl = Uri.parse('$SERVER_CREATE_ORDER_URL/verify_payment');
      final res = await http.post(
        verifyUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'bookingId': _currentBookingId,
        }),
      );

      if (res.statusCode == 200) {
        // server verified and updated booking -> reflect in UI
        ScaffoldMessenger.of(_ctx!).showSnackBar(const SnackBar(content: Text('Payment successful and verified!')));
      } else {
        // verification failed: optionally revert booking
        await BookingService.revertPendingBookingSeats(_currentBookingId!);
        ScaffoldMessenger.of(_ctx!).showSnackBar(SnackBar(content: Text('Payment verified failed: ${res.body}')));
      }
    } catch (e) {
      // network error — revert seats to avoid stuck pending
      if (_currentBookingId != null) {
        await BookingService.revertPendingBookingSeats(_currentBookingId!);
      }
      ScaffoldMessenger.of(_ctx!).showSnackBar(SnackBar(content: Text('Payment succeeded but verification error: $e')));
    } finally {
      _currentBookingId = null;
    }
  }

  static void _handlePaymentError(PaymentFailureResponse response) async {
    // revert pending booking if present
    if (_currentBookingId != null) {
      await BookingService.revertPendingBookingSeats(_currentBookingId!);
      _currentBookingId = null;
    }
    if (_ctx != null) {
      ScaffoldMessenger.of(_ctx!).showSnackBar(SnackBar(content: Text('Payment failed: ${response.message}')));
    }
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    if (_ctx != null) {
      ScaffoldMessenger.of(_ctx!).showSnackBar(SnackBar(content: Text('Wallet selected: ${response.walletName}')));
    }
  }

  static void dispose() {
    try {
      _razorpay.clear();
    } catch (_) {}
  }
}
