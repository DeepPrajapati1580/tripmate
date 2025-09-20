import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/trip_package.dart';
import '../../services/trip_service.dart';
import 'trip_bookings_page.dart';
import '../../widgets/trip_card.dart';

class AllTripsPage extends StatefulWidget {
  const AllTripsPage({super.key});

  @override
  State<AllTripsPage> createState() => _AllTripsPageState();
}

class _AllTripsPageState extends State<AllTripsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search trips by title or destination...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<TripPackage>>(
                stream: TripService.streamTripsByAgent(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No trips found"));
                  }

                  // Filter only booked trips
                  var trips = snapshot.data!
                      .where((t) => t.bookedSeats > 0)
                      .toList();

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    trips = trips.where((t) =>
                    t.title.toLowerCase().contains(_searchQuery) ||
                        t.destination.toLowerCase().contains(_searchQuery)
                    ).toList();
                  }

                  if (trips.isEmpty) {
                    return const Center(child: Text("No booked trips found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: trips.length,
                    itemBuilder: (_, index) {
                      final trip = trips[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TripCard(
                          trip: trip,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripBookingsPage(trip: trip),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
