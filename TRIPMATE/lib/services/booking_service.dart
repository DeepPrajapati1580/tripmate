import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/booking.dart';

class BookingService {
  static final CollectionReference<Map<String, dynamic>> _bookings =
  FirebaseFirestore.instance.collection('bookings');

  /// Create pending booking and update trip seats
  static Future<Booking> createPendingBooking({
    required String tripPackageId,
    required int seats,
    required int amount,
    String? razorpayOrderId,
    List<Map<String, dynamic>> travellers = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final tripRef =
    FirebaseFirestore.instance.collection('trip_packages').doc(tripPackageId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(tripRef);
      if (!snap.exists) throw Exception("Trip not found");

      final data = snap.data()!;
      final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
      final bookedSeatsList = List<int>.from(data['bookedSeatsList'] ?? []);

      if (bookedSeatsList.length + seats > capacity) {
        throw Exception("Not enough seats available");
      }

      // Generate seat numbers dynamically
      final List<int> newSeats = [];
      int seatNumber = 1;
      while (newSeats.length < seats) {
        if (!bookedSeatsList.contains(seatNumber)) {
          newSeats.add(seatNumber);
        }
        seatNumber++;
      }

      // Update trip with booked seats and travellers
      txn.update(tripRef, {
        'bookedSeats': bookedSeatsList.length + newSeats.length,
        'bookedSeatsList': FieldValue.arrayUnion(newSeats),
        if (travellers.isNotEmpty) 'travellers': FieldValue.arrayUnion(travellers),
      });

      // Create booking
      final docRef = _bookings.doc();
      txn.set(docRef, {
        'tripPackageId': tripPackageId,
        'userId': uid,
        'seats': seats,
        'amount': amount,
        'status': BookingStatus.pending.name,
        'razorpayOrderId': razorpayOrderId,
        'travellers': travellers,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final doc = await _bookings
        .where('tripPackageId', isEqualTo: tripPackageId)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    return Booking.fromDoc(doc.docs.first);
  }

  /// Mark booking as paid
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

  /// Cancel booking
  static Future<void> cancelBooking(String bookingId) async {
    await _bookings.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream user bookings
  static Stream<List<Booking>> streamUserBookings(String userId) {
    return _bookings
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList(),
    );
  }
}
