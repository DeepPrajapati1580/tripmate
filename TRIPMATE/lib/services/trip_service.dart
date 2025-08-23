// lib/services/trip_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_package.dart';

class TripService {
  static final _col = FirebaseFirestore.instance.collection('trip_packages');

  /// Stream all packages.
  /// - onlyUpcoming: whether to show only trips that haven't ended yet.
  /// - serverFilter: if true, tries to apply `where('endDate', >= now)` on server (may require composite index).
  /// If you want zero index problems, use onlyUpcoming: true, serverFilter: false (client filter).
  static Stream<List<TripPackage>> streamAll({bool onlyUpcoming = false, bool serverFilter = false}) {
    if (onlyUpcoming && serverFilter) {
      // Server-side filter (may require composite index)
      final q = _col
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('createdAt', descending: true);
      return q.snapshots().map((snap) => snap.docs.map((d) => TripPackage.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>)).toList());
    }

    // Simple server ordering only (no server range filter that triggers composite index).
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => TripPackage.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>)).toList();
          if (!onlyUpcoming) return list;
          // client-side filter
          final now = DateTime.now();
          return list.where((t) => t.endDate.isAfter(now) || t.endDate.isAtSameMomentAs(now)).toList();
        });
  }

  /// Stream packages created by a specific agent
  static Stream<List<TripPackage>> streamByAgent(String uid) {
    final q = _col.where('createdBy', isEqualTo: uid).orderBy('createdAt', descending: true);
    return q.snapshots().map((snap) => snap.docs.map((d) => TripPackage.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>)).toList());
  }
}
