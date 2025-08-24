import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/booking.dart';

class BookingService {
  static final CollectionReference<Map<String, dynamic>> _bookings =
  FirebaseFirestore.instance.collection('bookings');

  /// 🔹 Create a pending booking
  static Future<Booking> createPendingBooking({
    required String tripPackageId,
    required int seats,
    required int amount,
    String? razorpayOrderId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final data = {
      'tripPackageId': tripPackageId,
      'userId': uid,
      'seats': seats,
      'amount': amount,
      'status': BookingStatus.pending.name,
      'razorpayOrderId': razorpayOrderId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final doc = await _bookings.add(data);
    final snap = await doc.get();

    return Booking.fromDoc(snap); // ✅ now correct
  }

  /// 🔹 Mark booking as paid
  static Future<void> markPaid({
    required String bookingId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final doc = await _bookings.doc(bookingId).get();
    final data = doc.data();
    if (data == null) throw Exception('Booking not found');

    final orderId = data['razorpayOrderId'] as String?;
    if (orderId == null) throw Exception('Order not created');

    final verifyFn = FirebaseFunctions.instance.httpsCallable(
      'verifyRazorpaySignature',
    );
    final res = await verifyFn.call({
      'orderId': orderId,
      'paymentId': razorpayPaymentId,
      'signature': razorpaySignature,
    });

    final valid = (res.data as Map)['valid'] == true;
    if (!valid) throw Exception('Signature verification failed');

    await _bookings.doc(bookingId).update({
      'status': BookingStatus.paid.name,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Cancel booking
  static Future<void> cancelBooking(String bookingId) async {
    await _bookings.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Stream user bookings
  static Stream<List<Booking>> streamUserBookings(String userId) {
    return _bookings
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((d) => Booking.fromMap(d.id, d.data())) // ✅ use fromMap
          .toList(),
    );
  }
}
