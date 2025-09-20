import 'package:flutter/material.dart';
import '../../models/trip_package.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart'; // Assuming you have a UserService to get user details

class TripBookingsPage extends StatelessWidget {
  final TripPackage trip;

  const TripBookingsPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bookings for ${trip.title}"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: BookingService.streamBookingsForTrip(trip.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading bookings: ${snapshot.error}"),
            );
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          // Group bookings by userId
          final Map<String, List<Booking>> userBookings = {};
          for (var booking in bookings) {
            userBookings.putIfAbsent(booking.userId, () => []).add(booking);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: userBookings.entries.map((entry) {
              final userId = entry.key;
              final userBookingsList = entry.value;

              // Merge travellers from all bookings for this user
              final allTravellers = <Map<String, dynamic>>[];
              int totalSeats = 0;
              double totalAmount = 0;
              String status = 'PENDING';

              for (var b in userBookingsList) {
                allTravellers.addAll(b.travellers);
                totalSeats += b.seats;
                totalAmount += b.amount;
                status = b.status.toString().split('.').last.toUpperCase();
              }

              return FutureBuilder<String>(
                future: AuthService.getUsername(userId), // Get user name from your users collection
                builder: (context, userSnap) {
                  final username = userSnap.data ?? userId;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Booking by: $username",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Total Seats: $totalSeats"),
                          Text("Total Amount: ₹$totalAmount"),
                          Text(
                            "Status: $status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'PAID' ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (allTravellers.isNotEmpty) ...[
                            const Text(
                              "Travellers:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            ...allTravellers.map((t) => Text(" - ${t['name']} ")).toList(),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            "Latest Booking: ${userBookingsList.last.createdAt.toLocal()}".split(".").first,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
