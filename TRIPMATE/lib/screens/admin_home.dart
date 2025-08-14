import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  Future<void> _approve(String uid) {
    // NOTE: Client-side approve is ok for dev, but in production use server-side function & custom claims
    return FirebaseFirestore.instance.collection('users').doc(uid).update({'approved': true});
  }

  @override
  Widget build(BuildContext context) {
    final pendingStream = FirebaseFirestore.instance.collection('users').where('approved', isEqualTo: false).snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())]),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pendingStream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No pending accounts'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final data = docs[i].data();
              return ListTile(
                title: Text(data['displayName'] ?? data['email'] ?? 'No name'),
                subtitle: Text(data['role'] ?? 'customer'),
                trailing: ElevatedButton(onPressed: () => _approve(docs[i].id), child: const Text('Approve')),
              );
            },
          );
        },
      ),
    );
  }
}
