// lib/models/trip_package.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TripPackage {
  final String id;
  final String title;
  final String description;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int price;          // store in INR as integer
  final int capacity;
  final int bookedSeats;
  final String createdBy;   // uid of agent
  final DateTime createdAt; // server time when created
  final String? imageUrl;

  TripPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.capacity,
    required this.bookedSeats,
    required this.createdBy,
    required this.createdAt,
    this.imageUrl,
  });

  factory TripPackage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TripPackage(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      destination: d['destination'] ?? '',
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: (d['endDate'] as Timestamp).toDate(),
      price: (d['price'] as num?)?.toInt() ?? 0,
      capacity: (d['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: (d['bookedSeats'] as num?)?.toInt() ?? 0,
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: d['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'capacity': capacity,
      'bookedSeats': bookedSeats,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }
}
