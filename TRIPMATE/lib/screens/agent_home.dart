import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'agent/trip_form_page.dart';

class AgentHome extends StatelessWidget {
  const AgentHome({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TripFormPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: const Center(child: Text('Create and manage your trip packages.')),
    );
  }
}
