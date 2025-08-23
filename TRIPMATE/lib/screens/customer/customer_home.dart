// lib/screens/customer/customer_home.dart
import 'package:flutter/material.dart';
import '../../models/trip_package.dart';
import '../../services/trip_service.dart';
import '../../widgets/trip_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    // show all trips; we use client-side filtering for upcoming to avoid index issues
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TripPackage>>(
        stream: TripService.streamAll(onlyUpcoming: false, serverFilter: false),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading trips:\n${snap.error}'),
            ));
          }

          final trips = snap.data ?? [];
          if (trips.isEmpty) {
            return const Center(child: Text('No trip packages available right now.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trips.length,
            itemBuilder: (context, i) {
              final t = trips[i];
              return TripCard(trip: t, onTap: () {
                // TODO: navigate to Trip Details
              });
            },
          );
        },
      ),
    );
  }
}
