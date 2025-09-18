import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  static const int maxCommentLength = 250;

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
    required String comment,
    required this.rating,
    required this.createdAt,
  }) : comment = comment.length > maxCommentLength
      ? comment.substring(0, maxCommentLength) // ✅ auto-truncate
      : comment;

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
      comment: (comment ?? this.comment).length > maxCommentLength
          ? (comment ?? this.comment).substring(0, maxCommentLength)
          : (comment ?? this.comment),
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
      comment: (data['comment'] ?? '').toString().substring(
          0,
          (data['comment'] ?? '').toString().length > maxCommentLength
              ? maxCommentLength
              : (data['comment'] ?? '').toString().length),
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static FeedbackModel fromMap(String id, Map<String, dynamic> data) {
    final rawComment = data['comment'] ?? '';
    return FeedbackModel(
      id: id,
      userId: data['userId'] ?? '',
      agentId: data['agentId'] ?? '',
      tripId: data['tripId'] ?? '',
      comment: rawComment.toString().substring(
          0,
          rawComment.toString().length > maxCommentLength
              ? maxCommentLength
              : rawComment.toString().length),
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
