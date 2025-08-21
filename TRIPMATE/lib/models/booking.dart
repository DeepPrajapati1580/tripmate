import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String tripId;
  final int seatsBooked;
  final int totalAmount; // in minor units
  final String status; // pending / confirmed / cancelled
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.seatsBooked,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? tripId,
    int? seatsBooked,
    int? totalAmount,
    String? status,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tripId': tripId,
      'seatsBooked': seatsBooked,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static Booking fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      tripId: data['tripId'] ?? '',
      seatsBooked: (data['seatsBooked'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static Booking fromMap(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      userId: data['userId'] ?? '',
      tripId: data['tripId'] ?? '',
      seatsBooked: (data['seatsBooked'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Booking && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
