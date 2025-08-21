import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String agentId;
  final String tripId;
  final String comment;
  final int rating; // 1-5 stars
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.tripId,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? agentId,
    String? tripId,
    String? comment,
    int? rating,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      tripId: tripId ?? this.tripId,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'agentId': agentId,
      'tripId': tripId,
      'comment': comment,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static FeedbackModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      agentId: data['agentId'] ?? '',
      tripId: data['tripId'] ?? '',
      comment: data['comment'] ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static FeedbackModel fromMap(String id, Map<String, dynamic> data) {
    return FeedbackModel(
      id: id,
      userId: data['userId'] ?? '',
      agentId: data['agentId'] ?? '',
      tripId: data['tripId'] ?? '',
      comment: data['comment'] ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  bool get isPositive => rating >= 4;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FeedbackModel && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
