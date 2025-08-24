import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_package.dart';
import '../models/booking.dart';
import './booking_service.dart';

class TripService {
  static final _trips = FirebaseFirestore.instance.collection('trips');
  static final _db = FirebaseFirestore.instance;

  /// ✅ Stream all trips
  static Stream<List<TripPackage>> streamAll() {
    return _trips.snapshots().map(
          (snap) => snap.docs
          .map((doc) => TripPackage.fromDoc(doc))
          .toList(),
    );
  }

  /// ✅ Get available seats for a trip
  static Future<int> getAvailableSeats(String tripId) async {
    final doc = await _trips.doc(tripId).get();
    if (!doc.exists) return 0;
    final trip = TripPackage.fromDoc(doc);
    return trip.capacity - trip.bookedSeats;
  }

  /// ✅ Create a booking (transaction: update bookedSeats + add booking)
  static Future<void> createBooking({
    required String tripId,
    required int seats,
    required int amount,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final tripRef = _trips.doc(tripId);
    final bookingRef = _db.collection("bookings").doc();

    await _db.runTransaction((txn) async {
      final tripSnap = await txn.get(tripRef);
      if (!tripSnap.exists) throw Exception("Trip not found");

      final trip = TripPackage.fromDoc(tripSnap);
      final available = trip.capacity - trip.bookedSeats;

      if (available < seats) {
        throw Exception("Not enough seats available");
      }

      // ✅ update seats
      txn.update(tripRef, {"bookedSeats": trip.bookedSeats + seats});

      // ✅ add booking
      final booking = Booking(
        id: bookingRef.id,
        tripPackageId: tripId,
        userId: userId,
        seats: seats,
        amount: amount,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      txn.set(bookingRef, booking.toMap());
    });
  }

  /// ✅ Simple wrapper for createBooking
  static Future<void> bookTrip(
      String tripPackageId,
      int seats,
      int amount,
      ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final tripRef = _trips.doc(tripPackageId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(tripRef);
      if (!snap.exists) throw Exception("Trip not found");

      final data = snap.data()!;
      final capacity = data['capacity'] as int;
      final bookedSeats = data['bookedSeats'] as int? ?? 0;

      if (bookedSeats + seats > capacity) {
        throw Exception("Not enough seats available");
      }

      // 🔹 Create pending booking
      await BookingService.createPendingBooking(
        tripPackageId: tripPackageId,
        seats: seats,
        amount: amount,
      );

      // 🔹 Update booked seats count
      txn.update(tripRef, {
        'bookedSeats': bookedSeats + seats,
      });
    });
  }

  /// ✅ Cancel a booking (transaction: restore seats + mark cancelled)
  static Future<void> cancelBooking(Booking booking) async {
    final tripRef = _db.collection("trips").doc(booking.tripPackageId);
    final bookingRef = _db.collection("bookings").doc(booking.id);

    await _db.runTransaction((txn) async {
      final tripSnap = await txn.get(tripRef);
      if (!tripSnap.exists) throw Exception("Trip not found");

      final trip = TripPackage.fromDoc(tripSnap);

      // restore seats
      txn.update(tripRef, {
        "bookedSeats": trip.bookedSeats - booking.seats,
      });

      // update booking status
      txn.update(bookingRef, {"status": BookingStatus.cancelled.name});
    });
  }

  /// ✅ Update booked seats manually (helper)
  static Future<void> updateBookedSeats({
    required String tripId,
    required int delta,
  }) async {
    final tripRef = _db.collection("trips").doc(tripId);

    await _db.runTransaction((txn) async {
      final tripSnap = await txn.get(tripRef);
      if (!tripSnap.exists) throw Exception("Trip not found");

      final trip = TripPackage.fromDoc(tripSnap);
      final newSeats = trip.bookedSeats + delta;

      if (newSeats < 0 || newSeats > trip.capacity) {
        throw Exception("Invalid seat update");
      }

      txn.update(tripRef, {"bookedSeats": newSeats});
    });
  }
}
