// lib/services/razorpay_service.dart
import 'dart:convert';import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config.dart';
import 'booking_service.dart';

class RazorpayService {
  static late Razorpay _razorpay;
  static BuildContext? _ctx;
  static String? _currentBookingId;
  static String? _currentTripId; // store tripId for cancellation


  /// Initialize Razorpay instance; call once in initState
  static void init(BuildContext ctx) {
    _ctx = ctx;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Create order on server (server uses Razorpay secret)
  static Future<Map<String, dynamic>> createOrderOnServer({
    required int amountInPaise,
    required String bookingId,
  }) async {
    final url = Uri.parse('$SERVER_CREATE_ORDER_URL/create_order');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amountInPaise,
        'currency': 'INR',
        'receipt': bookingId,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to create order: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Open Razorpay checkout
  static void openCheckout({
    required String orderId,
    required int amountInPaise,
    required String bookingId,
    required String tripId,
    String? prefillContact,
    String? prefillEmail,
  }) {
    _currentBookingId = bookingId;
    _currentTripId = tripId;

    final options = {
      'key': RAZORPAY_KEY_ID,
      'amount': amountInPaise,
      'order_id': orderId,
      'name': 'TripMate',
      'description': 'Trip booking',
      'prefill': {
        'contact': prefillContact ?? '',
        'email': prefillEmail ?? '',
      },
      'theme': {'color': '#0f9d58'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (_ctx != null) {
        ScaffoldMessenger.of(_ctx!).showSnackBar(
          SnackBar(content: Text('Could not open payment: $e')),
        );
      }
    }
  }

  /// ✅ Cancel current booking safely
  static Future<void> _safeCancelBooking() async {
    if (_currentBookingId != null) {
      try {
        await BookingService.cancelBookingForUser(_currentBookingId!,_currentTripId!);
      } catch (e) {
        debugPrint('Error cancelling booking $_currentBookingId: $e');
      } finally {
        _currentBookingId = null;
      }
    }
  }

  static void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_ctx == null || _currentBookingId == null || _currentTripId == null) return;

    try {
      final verifyUrl = Uri.parse('$SERVER_CREATE_ORDER_URL/verify_payment');
      final res = await http.post(
        verifyUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'bookingId': _currentBookingId!,
        }),
      );

      if (res.statusCode == 200) {
        // Server verified, mark booking as paid
        await BookingService.markBookingPaid(
          bookingId: _currentBookingId!,
          paymentId: response.paymentId!,
          razorpayOrderId: response.orderId!,
        );

        ScaffoldMessenger.of(_ctx!).showSnackBar(
          const SnackBar(content: Text('Payment successful and verified!')),
        );

        // ✅ No need to decrement availableSeats here, already updated in bookTrip
        _currentBookingId = null;
        _currentTripId = null;

      } else {
        // Verification failed: cancel booking and revert seats
        await BookingService.cancelBookingForUser(_currentBookingId!, _currentTripId!);
        ScaffoldMessenger.of(_ctx!).showSnackBar(
          SnackBar(content: Text('Payment verification failed: ${res.body}')),
        );
      }
    } catch (e) {
      await BookingService.cancelBookingForUser(_currentBookingId!, _currentTripId!);
      ScaffoldMessenger.of(_ctx!).showSnackBar(
        SnackBar(content: Text('Payment succeeded but verification error: $e')),
      );
    }
  }


  static void _handlePaymentError(PaymentFailureResponse response) async {
    await _safeCancelBooking();
    if (_ctx != null) {
      ScaffoldMessenger.of(_ctx!).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message}')),
      );
    }
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    if (_ctx != null) {
      ScaffoldMessenger.of(_ctx!).showSnackBar(
        SnackBar(content: Text('Wallet selected: ${response.walletName}')),
      );
    }
  }

  static void dispose() {
    try {
      _razorpay.clear();
    } catch (_) {}
    _currentBookingId = null;
  }
}
