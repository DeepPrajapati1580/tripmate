import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trip_service.dart';
// import '../models/trip_model.dart';
import 'package:tripmate/models/trip_package.dart';

import 'package:firebase_auth/firebase_auth.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Trips'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TripPackage>>(
        stream: TripService.streamAll(onlyUpcoming: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Show Firestore error details to help debug during dev
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading trips:\n${snapshot.error}'),
              ),
            );
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return const Center(
              child: Text(
                'No trip packages available right now.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = trips[i];
              return Card(
                elevation: 1,
                child: ListTile(
                  leading: t.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            t.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.flight_takeoff),
                  title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${t.destination} • ₹${t.price}\n'
                    '${_formatDate(t.startDate)} → ${_formatDate(t.endDate)}',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Navigate to a trip details page if you add one
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailsPage(trip: t)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    // simple dd MMM yyyy without extra packages; you can switch to intl if you like
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
