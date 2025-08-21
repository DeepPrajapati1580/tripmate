// lib/models/trip_package.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TripPackage {
  final String id;
  final String title;
  final String description;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int pricePerSeat; // in minor units (e.g. paise or cents)
  final int capacity; // total number of seats
  final int bookedSeats; // already booked seats
  final String createdByUserId; // travel agent/manager ID
  final DateTime createdAt;
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
    required this.createdByUserId,
    required this.createdAt,
    this.imageUrl,
  });

  /// Create a new TripPackage with modifications
  TripPackage copyWith({
    String? id,
    String? title,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? pricePerSeat,
    int? capacity,
    int? bookedSeats,
    String? createdByUserId,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return TripPackage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      capacity: capacity ?? this.capacity,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Convert TripPackage -> Map<String, dynamic> (for Firestore)
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
      'createdByUserId': createdByUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }

  /// Create TripPackage from Firestore Document
  static TripPackage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TripPackage(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      pricePerSeat: (data['pricePerSeat'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: (data['bookedSeats'] as num?)?.toInt() ?? 0,
      createdByUserId: data['createdByUserId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String?,
    );
  }
}
