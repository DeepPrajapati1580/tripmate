// lib/screens/customer_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_package.dart';
import '../services/trip_service.dart';
import '../widgets/trip_card.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Trips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TripPackage>>(
        stream: TripService.streamAll(onlyUpcoming: true),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading trips:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final trips = snap.data ?? [];
          if (trips.isEmpty) {
            return const Center(
              child: Text(
                'No packages available yet.\nCheck back later!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: trips.length,
            itemBuilder: (_, i) {
              final trip = trips[i];
              return TripCard(
                trip: trip,
                onTap: () {
                  // Later you can add TripDetailsPage navigation here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Clicked on ${trip.title}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
