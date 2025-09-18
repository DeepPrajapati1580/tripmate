// lib/screens/customer/trip_feedback_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/feedback_service.dart';

class TripFeedbackPage extends StatefulWidget {
  final String tripId;

  const TripFeedbackPage({super.key, required this.tripId});

  @override
  State<TripFeedbackPage> createState() => _TripFeedbackPageState();
}

class _TripFeedbackPageState extends State<TripFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  int _rating = 0;
  bool _loading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _loading = true);

      await FeedbackService.submitFeedback(
        tripId: widget.tripId,
        userId: user.uid,
        rating: _rating,
        comment: _feedbackController.text.trim(),
      );

      _feedbackController.clear();
      setState(() => _rating = 0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteFeedback(String feedbackId) async {
    try {
      await FeedbackService.deleteFeedback(feedbackId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _buildRatingStars({required int rating, bool interactive = false}) {
    return Row(
      mainAxisAlignment:
      interactive ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return interactive
            ? IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => setState(() => _rating = index + 1),
        )
            : Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to view feedback")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Feedback"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FeedbackService.getTripFeedback(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedbackDocs = snapshot.data?.docs ?? [];

          // Convert to list of maps and fetch usernames asynchronously
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(feedbackDocs.map((doc) async {
              final data = doc.data();
              String username = 'Anonymous';
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['userId'])
                    .get();
                if (userDoc.exists && userDoc.data() != null) {
                  username = userDoc.data()!['name'] ?? 'Anonymous';
                }
              } catch (_) {}
              return {...data, 'username': username};
            })),
            builder: (context, snapshotWithUsers) {
              if (!snapshotWithUsers.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final feedbacks = snapshotWithUsers.data!;
              final userFeedback = feedbacks.firstWhere(
                    (fb) => fb['userId'] == user.uid,
                orElse: () => {},
              );
              final showForm = userFeedback.isEmpty;

              return Column(
                children: [
                  // ---------- Feedback Form ----------
                  if (showForm)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const Text(
                                  "Rate your trip",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                _buildRatingStars(
                                    rating: _rating, interactive: true),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _feedbackController,
                                  maxLines: 4,
                                  maxLength: 250,
                                  decoration: InputDecoration(
                                    labelText: "Your Feedback",
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(8)),
                                    counterText: "",
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Feedback is required";
                                    }
                                    if (value.trim().length > 250) {
                                      return "Feedback must be within 250 characters";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                    _loading ? null : _submitFeedback,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _loading
                                        ? const CircularProgressIndicator(
                                        color: Colors.white)
                                        : const Text("Submit Feedback",
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const Divider(height: 1),

                  // ---------- Feedback List ----------
                  Expanded(
                    child: feedbacks.isEmpty
                        ? const Center(child: Text("No feedback yet."))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        final fb = feedbacks[index];
                        final rating = fb['rating'] ?? 0;
                        final comment = fb['comment'] ?? '';
                        final userName = fb['username'] ?? 'Anonymous';
                        final userId = fb['userId'] ?? '';
                        final createdAt =
                        (fb['createdAt'] as Timestamp?)?.toDate();
                        final feedbackId = fb['id'] ?? '';

                        final isOwner = user.uid == userId;

                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          margin:
                          const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.teal,
                                      child: Text(
                                        userName.isNotEmpty
                                            ? userName[0].toUpperCase()
                                            : "A",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      createdAt != null
                                          ? "${createdAt.toLocal()}"
                                          .split(".")
                                          .first
                                          : "",
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12),
                                    ),
                                    if (isOwner)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteFeedback(feedbackId),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildRatingStars(rating: rating),
                                const SizedBox(height: 6),
                                Text(comment,
                                    style:
                                    const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
