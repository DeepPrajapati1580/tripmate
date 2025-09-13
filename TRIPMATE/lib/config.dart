// lib/config.dart
// Replace the values below with your keys / server URL.

/// Put your Razorpay **Key ID** here (test or live key)
const String RAZORPAY_KEY_ID = 'rzp_test_RGhdz5pB4jl1PO';

/// If you have a server to create Orders and verify signatures, set its base URL here.
/// Example for local development:
/// - Android emulator: use http://10.0.2.2:3000
/// - iOS simulator / web: use http://localhost:3000
///
/// If you don't want a server (not recommended for production), set this to null or '' and
/// the client will open checkout without a server-generated order (signature verification won't be possible).
const String SERVER_CREATE_ORDER_URL = 'http://localhost:3000';
