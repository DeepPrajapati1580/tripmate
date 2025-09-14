// lib/screens/customer/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_package.dart';
import '../../models/booking.dart';
import 'my_booking_details_page.dart';
import 'package:intl/intl.dart'; // ✅ import intl for formatting

/// Helper: convert Firestore status field to BookingStatus.
BookingStatus _parseBookingStatus(dynamic raw) {
  if (raw == null) return BookingStatus.pending;
  if (raw is BookingStatus) return raw;

  final s = raw.toString();
  try {
    return BookingStatus.values.firstWhere((e) {
      final name = e.toString().split('.').last;
      return name.toLowerCase() == s.toLowerCase();
    });
  } catch (_) {
    return BookingStatus.pending;
  }
}

DateTime _parseCreatedAt(dynamic raw) {
  if (raw == null) return DateTime.now();
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  try {
    return DateTime.parse(raw.toString());
  } catch (_) {
    return DateTime.now();
  }
}

int _toInt(dynamic n) {
  if (n == null) return 0;
  if (n is int) return n;
  if (n is num) return n.toInt();
  return int.tryParse(n.toString()) ?? 0;
}

List<Map<String, dynamic>> _toTravellers(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return {'name': e?.toString() ?? ''};
    }).toList();
  }
  return [];
}

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

          // Convert bookings safely
          final bookings = snapshot.data!.docs.map((doc) {
            final raw = doc.data();
            final Map<String, dynamic> data =
                (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

            return Booking(
              id: doc.id,
              tripPackageId: data['tripPackageId'] as String? ?? '',
              userId: data['userId'] as String? ?? '',
              seats: _toInt(data['seats']),
              amount: _toInt(data['amount']), // ✅ int not double
              travellers: _toTravellers(data['travellers']),
              status: _parseBookingStatus(data['status']),
              createdAt: _parseCreatedAt(data['createdAt']),
            );
          }).toList();

          // Group bookings by tripPackageId
          final Map<String, Booking> groupedBookings = {};
          for (final b in bookings) {
            if (b.tripPackageId.isEmpty) continue;
            if (groupedBookings.containsKey(b.tripPackageId)) {
              final existing = groupedBookings[b.tripPackageId]!;
              groupedBookings[b.tripPackageId] = Booking(
                id: existing.id,
                tripPackageId: existing.tripPackageId,
                userId: existing.userId,
                seats: existing.seats + b.seats,
                amount: existing.amount + b.amount,
                travellers: [...existing.travellers, ...b.travellers],
                status: existing.createdAt.isBefore(b.createdAt)
                    ? existing.status
                    : b.status,
                createdAt: existing.createdAt.isBefore(b.createdAt)
                    ? existing.createdAt
                    : b.createdAt,
              );
            } else {
              groupedBookings[b.tripPackageId] = b;
            }
          }

          final tripIds = groupedBookings.keys.toList();
          if (tripIds.isEmpty) {
            return const Center(child: Text("No valid bookings found"));
          }

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

              final trips = <String, TripPackage>{};
              for (final d in tripSnap.data!.docs) {
                final raw = d.data();
                final Map<String, dynamic> data =
                    (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
                try {
                  trips[d.id] = TripPackage.fromDoc(
                      d as DocumentSnapshot<Map<String, dynamic>>);
                } catch (_) {
                  // ✅ FIX: add all required fields with safe defaults
                  trips[d.id] = TripPackage(
                    id: d.id,
                    title: data['title'] as String? ?? 'Untitled',
                    description: data['description'] as String? ?? '',
                    source: data['source'] as String? ?? '',
                    destination: data['destination'] as String? ?? '',
                    startDate: _parseCreatedAt(data['startDate']),
                    endDate: _parseCreatedAt(data['endDate']),
                    price: _toInt(data['price']),
                    capacity: _toInt(data['capacity']),
                    bookedSeats: _toInt(data['bookedSeats']),
                    bookedSeatsList: (data['bookedSeatsList'] as List<dynamic>?)
                            ?.map((e) => (e as num).toInt())
                            .toList() ??
                        [],
                    createdBy: data['createdBy'] as String? ?? '',
                    createdAt: _parseCreatedAt(data['createdAt']),
                    travellers: _toTravellers(data['travellers']),
                    imageUrl: data['imageUrl'] as String?,
                  );
                }
              }

              final groupedList = groupedBookings.values.toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groupedList.length,
                itemBuilder: (context, index) {
                  final booking = groupedList[index];
                  final trip = trips[booking.tripPackageId];

                  if (trip == null) {
                    return const ListTile(
                        title: Text("Trip not found (maybe deleted)"));
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyBookingDetailsPage(
                              trip: trip,
                              booking: booking,
                            ),
                          ),
                        );
                      },
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
                      title: Text(
                        trip.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Destination: ${trip.destination}"),
                          Text("Seats: ${booking.seats}"),
                          Text(
                            "Total: ${NumberFormat.currency(
                                locale: 'en_IN',
                                symbol: '₹'
                            ).format(booking.amount)}",
                          ),
                          Text(
                            "Status: ${booking.status.name.toUpperCase()}",
                            style: TextStyle(
                              color: booking.status == BookingStatus.paid
                                  ? Colors.green
                                  : booking.status == BookingStatus.pending
                                  ? Colors.orange
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      ,
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
