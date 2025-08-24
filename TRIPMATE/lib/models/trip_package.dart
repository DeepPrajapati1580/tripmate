import 'package:cloud_firestore/cloud_firestore.dart';

class TripPackage {
  final String id;
  final String title;
  final String description;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int pricePerSeat;
  final int capacity;
  final int bookedSeats;
  final String? imageUrl;

  TripPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.pricePerSeat,
    required this.capacity,
    required this.bookedSeats,
    this.imageUrl,
  });

  /// Convert Firestore → Model
  factory TripPackage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TripPackage(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      destination: data['destination'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      pricePerSeat: data['pricePerSeat'] ?? 0,
      capacity: data['capacity'] ?? 0,
      bookedSeats: data['bookedSeats'] ?? 0,
      imageUrl: data['imageUrl'],
    );
  }

  /// Convert Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pricePerSeat': pricePerSeat,
      'capacity': capacity,
      'bookedSeats': bookedSeats,
      'imageUrl': imageUrl,
    };
  }
}
