import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';

class BookingService {
  static final CollectionReference<Map<String, dynamic>> _bookings =
      FirebaseFirestore.instance.collection('bookings');

  static final CollectionReference<Map<String, dynamic>> _trips =
      FirebaseFirestore.instance.collection('tripPackages');

  /// Create a pending booking AND decrement available seats inside a transaction.
  /// Returns the created Booking.
  static Future<Booking> createPendingBooking({
    required String tripPackageId,
    required int seats,
    required int amount,
    List<Map<String, dynamic>> travellers = const [],
    String? razorpayOrderId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final uid = user.uid;

    final bookingRef = _bookings.doc(); // new doc

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final tripRef = _trips.doc(tripPackageId);
      final tripSnap = await tx.get(tripRef);

      if (!tripSnap.exists) throw Exception('Trip not found');

      final tripData = tripSnap.data()!;
      final int availableSeats = (tripData['availableSeats'] ?? tripData['seats'] ?? 0) is int
          ? (tripData['availableSeats'] ?? tripData['seats'] ?? 0)
          : int.parse((tripData['availableSeats'] ?? tripData['seats'] ?? 0).toString());

      if (availableSeats < seats) throw Exception('Not enough seats available');

      // decrement seats
      tx.update(tripRef, {'availableSeats': availableSeats - seats});

      // create booking doc with status pending
      tx.set(bookingRef, {
        'tripPackageId': tripPackageId,
        'userId': uid,
        'seats': seats,
        'amount': amount,
        'status': BookingStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'travellers': travellers,
        'razorpayOrderId': razorpayOrderId,
      });
    });

    // read the doc back and return Booking
    final doc = await bookingRef.get();
    return Booking.fromMap(doc.id, doc.data()!);
  }

  /// Mark booking as paid (idempotent)
  static Future<void> markBookingPaid({
    required String bookingId,
    required String paymentId,
    required String razorpayOrderId,
  }) async {
    final bookingRef = _bookings.doc(bookingId);
    await bookingRef.update({
      'status': BookingStatus.paid.name,
      'paidAt': FieldValue.serverTimestamp(),
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
    });
  }

  /// Revert pending booking seats and mark booking cancelled (use when payment failed)
  static Future<void> revertPendingBookingSeats(String bookingId) async {
    final bookingRef = _bookings.doc(bookingId);
    final bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) return;
    final data = bookingSnap.data()!;
    final status = data['status'] ?? 'pending';
    if (status != BookingStatus.pending.name) return;

    final tripRef = _trips.doc(data['tripPackageId']);
    final seats = (data['seats'] ?? 0) is int ? data['seats'] : int.parse(data['seats'].toString());

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final tripSnap = await tx.get(tripRef);
      if (!tripSnap.exists) {
        // still mark cancelled
        tx.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      final tripData = tripSnap.data()!;
      final int availableSeats = (tripData['availableSeats'] ?? tripData['seats'] ?? 0) is int
          ? (tripData['availableSeats'] ?? tripData['seats'] ?? 0)
          : int.parse((tripData['availableSeats'] ?? tripData['seats'] ?? 0).toString());

      tx.update(tripRef, {'availableSeats': availableSeats + seats});
      tx.update(bookingRef, {
        'status': BookingStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
