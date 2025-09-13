// lib/screens/customer/trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_package.dart';
import 'trip_booking_page.dart';

class TripDetailsPage extends StatefulWidget {
  final String tripId;

  const TripDetailsPage({super.key, required this.tripId});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  TripPackage? trip;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrip();
  }

  Future<void> _fetchTrip() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("trip_packages")
          .doc(widget.tripId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Trip not found")));
        }
        return;
      }

      setState(() {
        trip = TripPackage.fromDoc(doc);
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (trip == null) {
      return const Scaffold(
        body: Center(child: Text("Trip not found")),
      );
    }

    final availableSeats = trip!.capacity - trip!.bookedSeats;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip!.title),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📷 Trip Gallery / Main Image
            if (trip!.gallery.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  itemCount: trip!.gallery.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          trip!.gallery[index],
                          width: 300,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (trip!.imageUrl != null && trip!.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                child: Image.network(
                  trip!.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip!.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.teal, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        trip!.destination,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.teal, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "${trip!.startDate.toString().split(' ').first} - ${trip!.endDate.toString().split(' ').first}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.money, color: Colors.teal, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "₹${trip!.price} per seat",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_seat, color: Colors.teal, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Available Seats: $availableSeats",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🏨 Hotel Section
                  if (trip!.hotelName != null && trip!.hotelName!.isNotEmpty) ...[
                    const Text(
                      "Hotel",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (trip!.imageUrl != null && trip!.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          trip!.imageUrl!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (trip!.gallery.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: trip!.gallery.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  trip!.gallery[index],
                                  width: 200,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // 📝 Itinerary
                  if (trip!.itinerary.isNotEmpty) ...[
                    const Text(
                      "Itinerary",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...trip!.itinerary.map((day) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                          "Day ${day['day']}: ${day['description']}"),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // 🍽 Meals
                  if (trip!.meals.isNotEmpty) ...[
                    const Text(
                      "Meals",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(trip!.meals.join(", ")),
                    const SizedBox(height: 16),
                  ],

                  // 🎯 Activities
                  if (trip!.activities.isNotEmpty) ...[
                    const Text(
                      "Activities",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(trip!.activities.join(", ")),
                    const SizedBox(height: 24),
                  ],

                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: availableSeats <= 0
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripBookingPage(trip: trip!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Book Now",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
