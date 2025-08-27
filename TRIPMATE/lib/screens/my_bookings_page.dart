// lib/screens/customer/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_package.dart';
import '../../models/booking.dart';

class MyBookingsPage extends StatelessWidget {
  final String userId; // pass current logged-in user's id

  const MyBookingsPage({super.key, required this.userId});

  Future<TripPackage?> _getTrip(String tripPackageId) async {
    final snap = await FirebaseFirestore.instance
        .collection("trips")
        .doc(tripPackageId)
        .get();

    if (!snap.exists) return null;
    return TripPackage.fromDoc(snap); // ✅ using fromDoc
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("userId", isEqualTo: userId)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings found"));
          }

          final bookings = snapshot.data!.docs
              .map((doc) => Booking.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>)) // ✅ cast
              .toList();

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return FutureBuilder<TripPackage?>(
                future: _getTrip(booking.tripPackageId), // ✅ booking has tripPackageId
                builder: (context, tripSnap) {
                  if (tripSnap.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text("Loading trip details..."),
                    );
                  }
                  if (!tripSnap.hasData) {
                    return const ListTile(
                      title: Text("Trip not found"),
                    );
                  }

                  final trip = tripSnap.data!;
                  return Card(
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: trip.imageUrl != null && trip.imageUrl!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          trip.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                          : const Icon(Icons.card_travel,
                          size: 40, color: Colors.teal),
                      title: Text(trip.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (trip.destination.isNotEmpty)
                            Text("Destination: ${trip.destination}"),
                          Text("Seats: ${booking.seats}"),
                          Text("Total: ₹${booking.amount ~/ 100}"),
                        ],
                      ),
                      trailing: Text(
                        booking.createdAt.toString().split(" ").first,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ),
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
