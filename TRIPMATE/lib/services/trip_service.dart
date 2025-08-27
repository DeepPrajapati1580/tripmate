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
  /// We keep filter client-side to avoid composite index hassles.
  static Stream<List<TripPackage>> streamAll({bool onlyUpcoming = true}) {
    return _col.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final items = snap.docs
          .map((d) => TripPackage.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      if (!onlyUpcoming) return items;

      final now = DateTime.now();
      return items.where((t) => !t.endDate.isBefore(DateTime(now.year, now.month, now.day))).toList();
    });
  }

  /// Stream packages created by a specific agent uid (for AgentHome)
  static Stream<List<TripPackage>> streamByAgent(String uid) {
    return _col.where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TripPackage.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Create a package
  static Future<void> create({
    required String title,
    required String description,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int price,
    required int capacity,
    required String createdBy,
    String? imageUrl,
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
    });
  }

  /// Update a package
  static Future<void> update(String id, Map<String, dynamic> data) {
    // Block updating createdAt/createdBy via UI for safety
    data.remove('createdAt');
    data.remove('createdBy');
    return _col.doc(id).set(data, SetOptions(merge: true));
  }

  /// Delete a package
  static Future<void> delete(String id) => _col.doc(id).delete();
}
