// lib/screens/customer/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_package.dart';
import '../../models/booking.dart';
import 'trip_details_page.dart';

class MyBookingsPage extends StatelessWidget {
  final String userId;

  const MyBookingsPage({super.key, required this.userId});

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
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings found"));
          }

          // ✅ Convert all bookings
          final bookings = snapshot.data!.docs
              .map((doc) =>
              Booking.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();

          // ✅ Group bookings by tripPackageId
          final Map<String, Booking> groupedBookings = {};
          for (var b in bookings) {
            if (groupedBookings.containsKey(b.tripPackageId)) {
              // sum seats and amount
              final existing = groupedBookings[b.tripPackageId]!;
              groupedBookings[b.tripPackageId] = Booking(
                id: existing.id,
                tripPackageId: existing.tripPackageId,
                userId: existing.userId,
                seats: existing.seats + b.seats,
                amount: existing.amount + b.amount,
                status: b.status, // you can decide which status to show
                createdAt: existing.createdAt.isBefore(b.createdAt)
                    ? existing.createdAt
                    : b.createdAt,
              );
            } else {
              groupedBookings[b.tripPackageId] = b;
            }
          }

          final tripIds = groupedBookings.keys.toList();

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection("trip_packages")
                .where(FieldPath.documentId, whereIn: tripIds)
                .get(),
            builder: (context, tripSnap) {
              if (tripSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!tripSnap.hasData || tripSnap.data!.docs.isEmpty) {
                return const Center(child: Text("No trip details found"));
              }

              final trips = {
                for (var d in tripSnap.data!.docs)
                  d.id: TripPackage.fromDoc(
                      d as DocumentSnapshot<Map<String, dynamic>>)
              };

              final groupedList = groupedBookings.values.toList();

              return ListView.builder(
                itemCount: groupedList.length,
                itemBuilder: (context, index) {
                  final booking = groupedList[index];
                  final trip = trips[booking.tripPackageId];

                  if (trip == null) {
                    return const ListTile(
                        title: Text("Trip not found (maybe deleted)"));
                  }

                  return Card(
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      onTap: () {
                        // ✅ Navigate to trip details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailsPage(trip: trip),
                          ),
                        );
                      },
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
                          Text("Destination: ${trip.destination}"),
                          Text("Seats: ${booking.seats}"),
                          Text("Total: ₹${booking.seats * trip.price}"),
                          Text("Status: ${booking.status.name}"),
                        ],
                      ),
                      trailing: Text(
                        booking.createdAt.toString().split(" ").first,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
