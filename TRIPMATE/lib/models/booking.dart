import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { paid, cancelled }

class Booking {
  final String id;
  final String tripPackageId;
  final String userId;
  final int seats;
  final int amount;
  final BookingStatus status;
  final DateTime createdAt;
  final List<Map<String, dynamic>> travellers;
  final String? paymentId;
  final DateTime? paidAt;
  final String? razorpayOrderId;

  Booking({
    required this.id,
    required this.tripPackageId,
    required this.userId,
    required this.seats,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.travellers,
    this.paymentId,
    this.paidAt,
    this.razorpayOrderId,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    // Handle Firestore Timestamp or DateTime
    final created = map['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else {
      createdAt = DateTime.now();
    }

    DateTime? paidAt;
    final paid = map['paidAt'];
    if (paid is Timestamp) {
      paidAt = paid.toDate();
    } else if (paid is DateTime) {
      paidAt = paid;
    }

    // Map status string to enum
    BookingStatus status;
    final statusStr = (map['status'] ?? '').toString().toLowerCase();
    if (statusStr == 'paid') {
      status = BookingStatus.paid;
    } else if (statusStr == 'cancelled') {
      status = BookingStatus.cancelled;
    } else {
      status = BookingStatus.paid; // default fallback
    }

    return Booking(
      id: id,
      tripPackageId: map['tripPackageId'] ?? '',
      userId: map['userId'] ?? '',
      seats: (map['seats'] ?? 0) is int ? map['seats'] : (map['seats'] ?? 0).toInt(),
      amount: (map['amount'] ?? 0) is int ? map['amount'] : (map['amount'] ?? 0).toInt(),
      status: status,
      createdAt: createdAt,
      travellers: List<Map<String, dynamic>>.from(map['travellers'] ?? []),
      paymentId: map['paymentId'],
      paidAt: paidAt,
      razorpayOrderId: map['razorpayOrderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "tripPackageId": tripPackageId,
      "userId": userId,
      "seats": seats,
      "amount": amount,
      "status": status.name, // store as string in Firestore
      "createdAt": createdAt,
      "travellers": travellers,
      "paymentId": paymentId,
      "paidAt": paidAt,
      "razorpayOrderId": razorpayOrderId,
    };
  }
}
