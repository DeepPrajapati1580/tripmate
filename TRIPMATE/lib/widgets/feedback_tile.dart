import 'package:flutter/material.dart';
import '../models/feedback_model.dart';

class FeedbackTile extends StatelessWidget {
  final FeedbackModel feedback;

  const FeedbackTile({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("⭐" * feedback.rating),
      subtitle: Text(feedback.comment),
      trailing: Text(
        "${feedback.createdAt.day}/${feedback.createdAt.month}/${feedback.createdAt.year}",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
