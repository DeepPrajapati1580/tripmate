import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Home'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())]),
      body: const Center(child: Text('Welcome, Customer!')),
    );
  }
}
