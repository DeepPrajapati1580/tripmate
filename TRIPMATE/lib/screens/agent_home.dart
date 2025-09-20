// lib/screens/agent_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_package.dart';
import '../services/trip_service.dart';
import '../widgets/trip_card.dart';
import 'agent/all_trips_page.dart';
import 'agent/trip_form_page.dart';
import 'agent/trip_edit_page.dart';
import 'agent/trip_bookings_page.dart';
import './account_page.dart';

class AgentHome extends StatefulWidget {
  const AgentHome({super.key});

  @override
  State<AgentHome> createState() => _AgentHomeState();
}

class _AgentHomeState extends State<AgentHome> {
  int _currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    // Pages for bottom navigation
    // Pages for bottom navigation
    final pages = [
      _buildAllTripsPage(),          // All trips created by agent
      const AllTripsPage(),          // Reuse your existing page that shows all booked trips
      AccountPage(),
    ];


    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'All Trips'
              : _currentIndex == 1
              ? 'Trip Bookings'
              : 'Account',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Trips",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Account",
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TripFormPage()),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Package",
          style: TextStyle(color: Colors.white),
        ),
      )
          : null,
    );
  }

  Widget _buildAllTripsPage() {
    return StreamBuilder<List<TripPackage>>(
      stream: TripService.streamByAgent(user!.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading packages:\n${snap.error}'),
            ),
          );
        }

        final trips = snap.data ?? [];
        if (trips.isEmpty) {
          return const Center(
            child: Text(
              'No packages created yet.\nTap + to add one!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: trips.length,
          itemBuilder: (_, i) {
            final trip = trips[i];
            return TripCard(
              trip: trip,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripBookingsPage(trip: trip),
                ),
              ),
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripEditPage(tripId: trip.id),
                ),
              ),
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Package'),
                    content: const Text('Delete this package?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await TripService.cancelBooking(trip.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Package deleted')),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
