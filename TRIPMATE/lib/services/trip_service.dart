import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_package.dart';

class TripService {
  static final CollectionReference<Map<String, dynamic>> _trips =
      FirebaseFirestore.instance.collection('trips');

  static Future<String> createTrip({
    required String title,
    required String description,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int pricePerSeat,
    required int capacity,
    String? imageUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _trips.add({
      'title': title,
      'description': description,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pricePerSeat': pricePerSeat,
      'capacity': capacity,
      'createdByUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'bookedSeats': 0,
    });
    return doc.id;
  }

  static Stream<List<TripPackage>> streamAllTrips() {
    return _trips
        .orderBy('startDate')
        .snapshots()
        .map((q) => q.docs.map((d) => TripPackage.fromDoc(d)).toList());
  }

  static Future<void> updateBookedSeats({
    required String tripId,
    required int delta,
  }) async {
    await _trips.doc(tripId).update({
      'bookedSeats': FieldValue.increment(delta),
    });
  }
}
