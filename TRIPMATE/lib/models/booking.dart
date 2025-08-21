// lib/models/booking.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for booking status
enum BookingStatus {
  pending,
  paid,
  cancelled,
}

/// Booking model
class Booking {
  final String id;
  final String tripPackageId;
  final String userId;
  final int seats;
  final int amount;
  final BookingStatus status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final DateTime createdAt;
  final DateTime? paidAt;

  Booking({
    required this.id,
    required this.tripPackageId,
    required this.userId,
    required this.seats,
    required this.amount,
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    required this.createdAt,
    this.paidAt,
  });

  /// Convert Booking -> Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'tripPackageId': tripPackageId,
      'userId': userId,
      'seats': seats,
      'amount': amount,
      'status': status.name,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  /// Convert Firestore doc -> Booking
  static Booking fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Booking(
      id: doc.id,
      tripPackageId: data['tripPackageId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      seats: (data['seats'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      status: BookingStatus.values.firstWhere(
            (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      razorpayOrderId: data['razorpayOrderId'] as String?,
      razorpayPaymentId: data['razorpayPaymentId'] as String?,
      razorpaySignature: data['razorpaySignature'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
    );
  }
}
