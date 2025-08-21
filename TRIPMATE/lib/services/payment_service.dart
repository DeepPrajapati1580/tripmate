import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  // Requires Firebase Cloud Function to create Razorpay order with secret key
  static final HttpsCallable _createOrderFn = FirebaseFunctions.instance
      .httpsCallable('createRazorpayOrder');

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    final res = await _createOrderFn.call({
      'amount': amount,
      'currency': currency,
      'receipt': receipt,
      'notes': notes ?? {},
    });
    final data = (res.data is String)
        ? jsonDecode(res.data as String)
        : Map<String, dynamic>.from(res.data as Map);
    return data;
  }
}
