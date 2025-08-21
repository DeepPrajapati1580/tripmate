import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<TripPackage> _trips = [];
  List<TripPackage> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 🔹 Fetch trips from Firestore
  Future<void> fetchTrips() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('trips').get();
      _trips = snapshot.docs.map((doc) => TripPackage.fromDoc(doc)).toList();
    } catch (e) {
      debugPrint("❌ Error fetching trips: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 🔹 Add a trip to Firestore
  Future<void> addTrip(TripPackage trip) async {
    try {
      await _firestore.collection('trips').add(trip.toMap());
      await fetchTrips(); // refresh list
    } catch (e) {
      debugPrint("❌ Error adding trip: $e");
    }
  }

  /// 🔹 Update a trip in Firestore
  Future<void> updateTrip(TripPackage updated) async {
    try {
      await _firestore.collection('trips').doc(updated.id).update(updated.toMap());
      await fetchTrips(); // refresh list
    } catch (e) {
      debugPrint("❌ Error updating trip: $e");
    }
  }

  /// 🔹 Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).delete();
      _trips.removeWhere((trip) => trip.id == tripId);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error deleting trip: $e");
    }
  }
}
