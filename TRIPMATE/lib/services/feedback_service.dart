import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/user_model.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  static final _firestore = FirebaseFirestore.instance;

  /// Submit feedback for a trip (with username)
  static Future<void> submitFeedback({
    required String tripId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final feedbackRef = _firestore.collection("feedback").doc();

    String? username;

    try {
      // Fetch username
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final user = AppUser.fromDoc(userDoc);
        username = user.name ?? 'Anonymous';
      }
    } catch (e) {
      debugPrint("Error fetching user or trip info: $e");
    }

    final feedback = FeedbackModel(
      id: feedbackRef.id,
      userId: userId,
      tripId: tripId,
      comment: comment,
      rating: rating,
      createdAt: DateTime.now(),
      username: username ?? "Anonymous",
    );

    await feedbackRef.set(feedback.toMap());
    await updateTripAverageRating(tripId);
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
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserTripFeedback(
      String tripId, String userId) {
    return _firestore
        .collection('feedback')
        .where('tripId', isEqualTo: tripId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots();
  }

  /// Stream feedbacks with usernames (live updates)
  static Stream<List<FeedbackModel>> getTripFeedbackWithUsernamesStream(String tripId) {
    return _firestore
        .collection('feedback')
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedbackModel.fromDoc(doc)).toList();
    });
  }

  /// Recalculate and update the average rating for a trip
  static Future<void> updateTripAverageRating(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('tripId', isEqualTo: tripId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // No feedbacks yet — set avgRating to null or 0
        await _firestore.collection('trip_packages').doc(tripId).update({'avgRating': null});
        return;
      }

      final totalRating = querySnapshot.docs.fold<int>(
        0,
            (sum, doc) => sum + (doc.data()['rating'] ?? 0) as int,
      );

      final avgRating = totalRating / querySnapshot.docs.length;

      await _firestore
          .collection('trip_packages')
          .doc(tripId)
          .update({'avgRating': avgRating});
    } catch (e) {
      debugPrint('Error updating avgRating: $e');
    }
  }

}
