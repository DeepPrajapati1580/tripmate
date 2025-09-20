// lib/screens/customer_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_package.dart';
import '../services/trip_service.dart';
import '../widgets/trip_card.dart';
import 'customer/trip_details_page.dart';
import 'customer/my_bookings_page.dart';
import 'account_page.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  String _searchQuery = '';
  int _selectedIndex = 0; // 0 = Trips, 1 = My Bookings, 2 = Account

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Available Trips'
              : _selectedIndex == 1
              ? 'My Bookings'
              : 'Account',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // --- Trips Tab ---
            Column(
              children: [
                // 🔎 Search Box
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
                // 📦 Trip List
                Expanded(
                  child: StreamBuilder<List<TripPackage>>(
                    stream: TripService.streamAllTrips(onlyUpcoming: true),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
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

                      // 🔍 Filter by search query
                      if (_searchQuery.isNotEmpty) {
                        trips = trips.where((trip) {
                          return trip.title
                              .toLowerCase()
                              .contains(_searchQuery) ||
                              trip.destination
                                  .toLowerCase()
                                  .contains(_searchQuery);
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

                      // ✅ Show TripCard per row
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: trips.length,
                        itemBuilder: (_, i) {
                          final trip = trips[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TripCard(
                              trip: trip,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TripDetailsPage(tripId: trip.id),
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

            // --- My Bookings Tab ---
            MyBookingsPage(userId: user?.uid ?? ''),

            // --- Account Tab ---
            AccountPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.airplanemode_active),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
