// lib/services/trip_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_package.dart';


class TripService {
  static final _col =
  FirebaseFirestore.instance.collection('trip_packages')
      .withConverter<Map<String, dynamic>>(
    fromFirestore: (snap, _) => snap.data() ?? {},
    toFirestore: (data, _) => data,
  );

  /// Stream ALL packages (for customers).
  static Stream<List<TripPackage>> streamAll({bool onlyUpcoming = true}) {
    return _col.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final items = snap.docs
          .map((d) =>
          TripPackage.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      if (!onlyUpcoming) return items;

      final now = DateTime.now();
      return items
          .where((t) => !t.endDate
          .isBefore(DateTime(now.year, now.month, now.day)))
          .toList();
    });
  }

  /// Stream packages created by a specific agent uid
  static Stream<List<TripPackage>> streamByAgent(String uid) {
    return _col
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) =>
        TripPackage.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  /// 🔹 Create a new trip package (for admin/agent)
  static Future<void> create({
    required String title,
    required String description,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int price,
    required int capacity,
    required String createdBy,
    String? imageUrl,       // 👈 Already uploaded Cloudinary URL
    String? imagePublicId,  // 👈 Already uploaded Cloudinary publicId
  }) async {
    await _col.add({
      'title': title,
      'description': description,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'capacity': capacity,
      'bookedSeats': 0,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
    });
  }

  /// ✅ Book trip with seat numbers
  static Future<void> bookTrip({
    required String tripId,
    required List<int> seats,
    required String userId,
  }) async {
    final tripRef = _col.doc(tripId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(tripRef);
      if (!snapshot.exists) {
        throw Exception("Trip not found");
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final bookedSeats = (data['bookedSeats'] as num?)?.toInt() ?? 0;
      final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
      final bookedSeatsList = (data['bookedSeatsList'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList() ?? [];

      // check if requested seats are already taken
      for (final seat in seats) {
        if (bookedSeatsList.contains(seat)) {
          throw Exception("Seat $seat is already booked");
        }
      }

      if (bookedSeats + seats.length > capacity) {
        throw Exception("Not enough seats available");
      }

      // ✅ Update trip's booked seats
      txn.update(tripRef, {
        'bookedSeats': bookedSeats + seats.length,
        'bookedSeatsList': FieldValue.arrayUnion(seats),
      });
    });

    // ✅ Create a booking document for the user
    final tripSnapshot = await tripRef.get();
    final tripData = tripSnapshot.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance.collection('bookings').add({
      'tripPackageId': tripId,
      'userId': userId,
      'seats': seats.length,
      'amount': seats.length * (tripData['price'] ?? 0),
      'status': 'pending', // change to 'paid' if payment is integrated
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  /// Update a package
  static Future<void> update(String id, Map<String, dynamic> data) async {
    final docRef = _col.doc(id);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update(data);
    } else {
      throw Exception("Trip with id $id does not exist");
    }
  }

  /// Delete a package
  static Future<void> delete(String id) => _col.doc(id).delete();
}
