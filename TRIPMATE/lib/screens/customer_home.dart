// lib/screens/customer_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_package.dart';
import '../services/trip_service.dart';
import '../widgets/trip_card.dart';
import 'trip_details_page.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  String _searchQuery = '';

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
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search trips by title or destination...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // 🔹 StreamBuilder for trips
          Expanded(
            child: StreamBuilder<List<TripPackage>>(
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

                var trips = snap.data ?? [];

                // 🔍 Filter trips by search query
                if (_searchQuery.isNotEmpty) {
                  trips = trips.where((trip) {
                    return trip.title.toLowerCase().contains(_searchQuery) ||
                        trip.destination.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (trips.isEmpty) {
                  return const Center(
                    child: Text(
                      'No packages found.\nTry another search!',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailsPage(trip: trip),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
