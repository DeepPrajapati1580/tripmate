import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import 'package:collection/collection.dart'; // For DeepCollectionEquality

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

  /// ✅ Cancel all bookings of a user for a specific trip (post-payment)
  static Future<void> cancelBookingForUser(String userId, String tripId) async {
    final tripRef = _trips.doc(tripId);

    // 1️⃣ Get all bookings of this user for this trip
    final userBookingsSnap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('tripPackageId', isEqualTo: tripId)
        .get();

    if (userBookingsSnap.docs.isEmpty) return;

    // 2️⃣ Prepare total seats and travellers to remove
    int totalSeatsToRemove = 0;
    List<Map<String, dynamic>> travellersToRemove = [];

    for (var doc in userBookingsSnap.docs) {
      final data = doc.data();
      final seats = (data['seats'] ?? 0) is int
          ? data['seats'] as int
          : int.tryParse(data['seats'].toString()) ?? 0;
      totalSeatsToRemove += seats;

      travellersToRemove.addAll(
        List<Map<String, dynamic>>.from(data['travellers'] ?? []),
      );
    }

    final deepEq = const DeepCollectionEquality();

    // 3️⃣ Run transaction to update trip and delete bookings
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final tripSnap = await tx.get(tripRef);

      if (tripSnap.exists) {
        final tripData = tripSnap.data()!;

        final int bookedSeats = (tripData['bookedSeats'] ?? 0) is int
            ? tripData['bookedSeats'] as int
            : int.tryParse(tripData['bookedSeats'].toString()) ?? 0;

        final int availableSeats = (tripData['availableSeats'] ??
            (tripData['capacity'] - bookedSeats)) is int
            ? tripData['availableSeats'] as int
            : int.tryParse(tripData['availableSeats'].toString()) ?? 0;

        final List<Map<String, dynamic>> existingTravellers =
        List<Map<String, dynamic>>.from(tripData['travellers'] ?? []);

        // Remove only travellers of this user using deep equality
        final updatedTravellers = existingTravellers
            .where((t) => !travellersToRemove.any((tr) => deepEq.equals(t, tr)))
            .toList();

        final newBookedSeats = (bookedSeats - totalSeatsToRemove).clamp(0, bookedSeats);
        final newAvailableSeats = availableSeats + totalSeatsToRemove;

        tx.update(tripRef, {
          'bookedSeats': newBookedSeats,
          'availableSeats': newAvailableSeats,
          'travellers': updatedTravellers,
        });
      }

      // Delete all bookings of this user for the trip
      for (var doc in userBookingsSnap.docs) {
        tx.delete(doc.reference);
      }
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

}
