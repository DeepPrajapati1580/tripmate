import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingService {
  static final CollectionReference<Map<String, dynamic>> _bookings =
  FirebaseFirestore.instance.collection('bookings');

  static final CollectionReference<Map<String, dynamic>> _trips =
  FirebaseFirestore.instance.collection('trip_packages'); // Trip collection

  /// ✅ Mark booking as paid (idempotent)
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

  /// ✅ Cancel a booking and revert seats (used if payment fails or booking is cancelled by user)
  static Future<void> cancelBooking(String bookingId) async {
    final bookingRef = _bookings.doc(bookingId);
    final bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) return;

    final data = bookingSnap.data()!;
    final int seats = (data['seats'] ?? 0) is int
        ? data['seats'] as int
        : int.tryParse(data['seats'].toString()) ?? 0;

    final tripRef = _trips.doc(data['tripPackageId']);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final tripSnap = await tx.get(tripRef);

      if (tripSnap.exists) {
        final tripData = tripSnap.data()!;
        final int bookedSeats = (tripData['bookedSeats'] ?? 0) is int
            ? tripData['bookedSeats']
            : int.tryParse(tripData['bookedSeats'].toString()) ?? 0;

        // ✅ Safely decrement bookedSeats
        final newSeats = (bookedSeats - seats).clamp(0, bookedSeats);

        tx.update(tripRef, {
          'bookedSeats': newSeats,
        });
      }

      // ✅ Mark booking as cancelled
      tx.update(bookingRef, {
        'status': BookingStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ✅ Stream bookings for a given trip (for travel agent view)
  static Stream<List<Booking>> streamBookingsForTrip(String tripId) {
    return _bookings
        .where('tripPackageId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// ✅ Fetch all bookings for a given trip (one-time fetch)
  static Future<List<Booking>> fetchBookingsForTrip(String tripId) async {
    final querySnap = await _bookings
        .where('tripPackageId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnap.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// ✅ Delete a booking (fully removes booking, decrements bookedSeats, removes travellers)
  static Future<void> deleteBooking(String bookingId) async {
    final bookingRef = _bookings.doc(bookingId);
    final bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) throw Exception("Booking not found");

    final bookingData = bookingSnap.data() as Map<String, dynamic>;
    final tripId = bookingData['tripPackageId'] as String;
    final travellers =
    List<Map<String, dynamic>>.from(bookingData['travellers'] ?? []);
    final seats = (bookingData['seats'] as num?)?.toInt() ?? travellers.length;

    final tripRef = _trips.doc(tripId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final tripSnap = await txn.get(tripRef);
      if (!tripSnap.exists) throw Exception("Trip not found");

      final tripData = tripSnap.data() as Map<String, dynamic>;
      final bookedSeats = (tripData['bookedSeats'] as num?)?.toInt() ?? 0;

      // ✅ Decrement seats, but never go negative
      final newSeats = (bookedSeats - seats).clamp(0, bookedSeats);

      // ✅ Remove travellers of this booking from the trip's travellers list
      final existingTravellers =
      List<Map<String, dynamic>>.from(tripData['travellers'] ?? []);
      final updatedTravellers =
      existingTravellers.where((t) => !travellers.contains(t)).toList();

      txn.update(tripRef, {
        'bookedSeats': newSeats,
        'travellers': updatedTravellers,
      });

      // ✅ Delete the booking itself
      txn.delete(bookingRef);
    });
  }
}
