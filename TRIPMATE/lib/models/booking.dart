import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, paid, cancelled }

class Booking {
  final String id;
  final String tripPackageId;
  final String userId;
  final int seats;
  final int amount;
  final BookingStatus status;
  final DateTime createdAt;
  final List<Map<String, dynamic>> travellers; // ✅ List of {'seatNumber': int, 'name': String}

  Booking({
    required this.id,
    required this.tripPackageId,
    required this.userId,
    required this.seats,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.travellers = const [],
  });

  /// Use when you already have a Firestore DocumentSnapshot
  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Booking(
      id: doc.id,
      tripPackageId: data['tripPackageId'],
      userId: data['userId'],
      seats: (data['seats'] as num).toInt(),
      amount: (data['amount'] as num).toInt(),
      status: BookingStatus.values.byName(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      travellers: List<Map<String, dynamic>>.from(data['travellers'] ?? []),
    );
  }

  /// Use when you only have `id` + `Map`
  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      tripPackageId: data['tripPackageId'],
      userId: data['userId'],
      seats: (data['seats'] as num).toInt(),
      amount: (data['amount'] as num).toInt(),
      status: BookingStatus.values.byName(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      travellers: List<Map<String, dynamic>>.from(data['travellers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "tripPackageId": tripPackageId,
      "userId": userId,
      "seats": seats,
      "amount": amount,
      "status": status.name,
      "createdAt": createdAt,
      "travellers": travellers, // ✅ include travellers
    };
  }
}
