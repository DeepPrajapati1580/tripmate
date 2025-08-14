import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending approval')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Your account is pending admin approval. You will be notified once approved.', textAlign: TextAlign.center),
          ),
          ElevatedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Sign out')),
        ]),
      ),
    );
  }
}
