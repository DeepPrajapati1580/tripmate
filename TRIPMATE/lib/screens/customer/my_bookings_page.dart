// lib/screens/customer/my_bookings_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/trip_package.dart';
import '../../../models/booking.dart';
import '../../services/booking_service.dart';
import 'my_booking_details_page.dart';
import 'package:intl/intl.dart'; // ✅ import intl for formatting

/// Helper: convert Firestore status field to BookingStatus.
BookingStatus _parseBookingStatus(dynamic raw) {
  if (raw == null) return BookingStatus.paid; // default to paid
  if (raw is BookingStatus) return raw;

  final s = raw.toString().toLowerCase();
  if (s == 'paid') return BookingStatus.paid;
  if (s == 'cancelled') return BookingStatus.cancelled;
  return BookingStatus.paid; // fallback
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
              amount: _toInt(data['amount']),
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

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyBookingDetailsPage(
                            booking: booking,
                            trip: trip,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: Colors.teal.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Leading image/icon
                            trip.imageUrl != null && trip.imageUrl!.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                trip.imageUrl!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            )
                                : const Icon(Icons.card_travel, size: 60, color: Colors.teal),
                            const SizedBox(width: 12),
                            // Booking info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Destination: ${trip.destination}"),
                                  Text("Seats: ${booking.seats}"),
                                  Text(
                                    "Total: ${NumberFormat.currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                    ).format(booking.amount)}",
                                  ),
                                  Text(
                                    "Status: ${booking.status.name.toUpperCase()}",
                                    style: TextStyle(
                                      color: booking.status == BookingStatus.paid
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Cancel Button
                                  if (booking.status == BookingStatus.paid)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.cancel, size: 18),
                                        label: const Text("Cancel Booking"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          textStyle: const TextStyle(fontSize: 14),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: Colors.white, // ✅ ensures visible background
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16), // rounded corners
                                              ),
                                              title: const Text(
                                                "Confirm Cancellation",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: const Text(
                                                "Are you sure you want to cancel this booking? This action cannot be undone.",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.grey[200], // light grey button
                                                    foregroundColor: Colors.black87,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: const Text("No"),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.red[50], // light red background
                                                    foregroundColor: Colors.redAccent, // red text
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: const Text("Yes, Cancel"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              final userId = FirebaseAuth.instance.currentUser!.uid;
                                              final tripId = booking.tripPackageId;

                                              await BookingService.cancelBookingForUser(userId, tripId);

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("All your bookings for this trip have been cancelled successfully")),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Error cancelling booking: $e")),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy').format(booking.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
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
