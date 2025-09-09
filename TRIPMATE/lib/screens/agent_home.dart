// lib/screens/agent_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_package.dart';
import '../services/trip_service.dart';
import 'agent/trip_form_page.dart';
import 'agent/trip_edit_page.dart';

class AgentHome extends StatelessWidget {
  const AgentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agent Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TripFormPage()),
        ),
        icon: const Icon(
          Icons.add,        // The + icon
          color: Colors.white, // ✅ White color
        ),
        label: const Text(
          "New Package",
          style: TextStyle(color: Colors.white), // ✅ White text
        ),
      ),

      body: user == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<List<TripPackage>>(
        stream: TripService.streamByAgent(user.uid),
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
          final items = snap.data ?? [];
          if (items.isEmpty) {
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
            itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripEditPage(
                          tripId: t.id,
                          existingData: {
                            'title': t.title,
                            'description': t.description,
                            'destination': t.destination,
                            'startDate': Timestamp.fromDate(t.startDate),
                            'endDate': Timestamp.fromDate(t.endDate),
                            'price': t.price,
                            'capacity': t.capacity,
                            'bookedSeats': t.bookedSeats,
                            'bookedSeatsList': t.bookedSeatsList,
                            'imageUrl': t.imageUrl,
                          },
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Safe handling for imageUrl
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: (t.imageUrl ?? '').isNotEmpty
                            ? Image.network(
                          t.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          height: 160,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image,
                              size: 50, color: Colors.grey),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.destination,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.deepPurple),
                                const SizedBox(width: 4),
                                Text(
                                  "${t.startDate.day}/${t.startDate.month}/${t.startDate.year} - "
                                      "${t.endDate.day}/${t.endDate.month}/${t.endDate.year}",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.people,
                                    size: 16, color: Colors.deepPurple),
                                const SizedBox(width: 4),
                                Text(
                                  "Capacity: ${t.capacity}, Booked: ${t.bookedSeats}",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "₹${t.price}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TripEditPage(
                                              tripId: t.id,
                                              existingData: {
                                                'title': t.title,
                                                'description':
                                                t.description,
                                                'destination':
                                                t.destination,
                                                'startDate':
                                                Timestamp.fromDate(
                                                    t.startDate),
                                                'endDate': Timestamp
                                                    .fromDate(t.endDate),
                                                'price': t.price,
                                                'capacity': t.capacity,
                                                'bookedSeats':
                                                t.bookedSeats,
                                                'bookedSeatsList':
                                                t.bookedSeatsList,
                                                'imageUrl': t.imageUrl,
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        final confirm =
                                        await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                                'Delete Package'),
                                            content: const Text(
                                                'Delete this package?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        ctx, false),
                                                child:
                                                const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        ctx, true),
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                  Colors.red,
                                                ),
                                                child:
                                                const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await TripService.delete(t.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Package deleted')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
