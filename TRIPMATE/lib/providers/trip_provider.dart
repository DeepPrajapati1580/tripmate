import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class TripProvider with ChangeNotifier {
  List<TripPackage> _trips = [];

  List<TripPackage> get trips => _trips;

  void setTrips(List<TripPackage> trips) {
    _trips = trips;
    notifyListeners();
  }

  void addTrip(TripPackage trip) {
    _trips.add(trip);
    notifyListeners();
  }

  void updateTrip(TripPackage updated) {
    final index = _trips.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _trips[index] = updated;
      notifyListeners();
    }
  }
}
