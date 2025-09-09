import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_package.dart';
import '../../models/booking.dart';
import './trip_details_page.dart'; // ✅ Import TripDetailsPage

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
              .map((doc) =>
              Booking.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();

          final tripIds = bookings.map((b) => b.tripPackageId).toSet().toList();

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

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final trip = trips[booking.tripPackageId];

                  if (trip == null) {
                    return const ListTile(
                        title: Text("Trip not found (maybe deleted)"));
                  }

                  return GestureDetector(
                    onTap: () {
                      // ✅ Navigate to TripDetailsPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripDetailsPage(trip: trip),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: trip.imageUrl != null &&
                            trip.imageUrl!.isNotEmpty
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
                            Text("Total: ₹${booking.amount ~/ 100}"),
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
