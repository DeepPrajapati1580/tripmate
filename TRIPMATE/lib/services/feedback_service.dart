import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class FeedbackService {
  static final _firestore = FirebaseFirestore.instance;

  /// Submit feedback for a trip
  static Future<void> submitFeedback({
    required String tripId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final feedbackRef = _firestore.collection("feedback").doc();

    await feedbackRef.set({
      "id": feedbackRef.id,
      "tripId": tripId,
      "userId": userId,
      "rating": rating,
      "comment": comment,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// Delete feedback by ID
  static Future<void> deleteFeedback(String feedbackId) async {
    await _firestore.collection('feedback').doc(feedbackId).delete();
  }

  /// Get all feedbacks for a specific trip
  static Stream<QuerySnapshot<Map<String, dynamic>>> getTripFeedback(String tripId) {
    return _firestore
        .collection("feedback")
        .where("tripId", isEqualTo: tripId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// Get feedbacks submitted by a specific user
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserFeedback(String userId) {
    return _firestore
        .collection("feedback")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// Get feedback submitted by a specific user for a trip (limit 1)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserTripFeedback(String tripId, String userId) {
    return _firestore
        .collection('feedback')
        .where('tripId', isEqualTo: tripId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots();
  }

  /// Fetch feedbacks with usernames (for showing in UI)
  static Future<List<Map<String, dynamic>>> getTripFeedbackWithUsernames(String tripId) async {
    final feedbackSnapshot = await _firestore
        .collection('feedback')
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .get();

    final feedbacks = feedbackSnapshot.docs;

    // Fetch usernames for each feedback
    final results = await Future.wait(feedbacks.map((doc) async {
      final data = doc.data();
      final userId = data['userId'] as String?;

      String username = 'Anonymous';
      if (userId != null && userId.isNotEmpty) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData.containsKey('name')) {
              username = userData['name'] ?? 'Anonymous';
            }
          }
        } catch (e) {
          debugPrint("Error fetching username for $userId: $e");
          // Keep username as 'Anonymous' on error
        }
      }

      return {
        ...data,
        'username': username, // include actual username in feedback
      };
    }).toList());

    return results;
  }

}
