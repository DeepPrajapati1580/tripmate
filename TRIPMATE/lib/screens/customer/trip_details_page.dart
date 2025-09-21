// lib/screens/customer/trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/trip_package.dart';
import 'trip_booking_page.dart';
import '../trip_feedback_page.dart'; // ✅ Import Feedback Page

class TripDetailsPage extends StatefulWidget {
  final String tripId;

  const TripDetailsPage({super.key, required this.tripId});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  TripPackage? trip;
  bool loading = true;

  final currencyFormatter = NumberFormat("#,##0", "en_IN");

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
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Trip not found")));
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
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📷 Trip Gallery
            if (trip!.gallery.isNotEmpty)
              _buildImageGallery("Trip Gallery", trip!.gallery)
            else if (trip!.imageUrl != null && trip!.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                  // 🏨 Hotel Section
                  if (trip!.hotelName != null && trip!.hotelName!.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip!.hotelName!,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (trip!.hotelStars != null)
                              Row(
                                children: List.generate(
                                  trip!.hotelStars!,
                                  (index) => const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (trip!.hotelDescription != null)
                              Text(
                                trip!.hotelDescription!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            const SizedBox(height: 12),
                            if (trip!.hotelMainImage != null &&
                                trip!.hotelMainImage!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  trip!.hotelMainImage!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (trip!.hotelGallery.isNotEmpty)
                              _buildImageGallery(
                                  "Hotel Gallery", trip!.hotelGallery),
                          ],
                        ),
                      ),
                    ),

                  // Trip Info
                  Text(
                    trip!.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _iconTextRow(Icons.place, trip!.destination),
                  const SizedBox(height: 8),
                  _iconTextRow(
                      Icons.date_range,
                      "${trip!.startDate.toString().split(' ').first} - ${trip!.endDate.toString().split(' ').first}",
                      color: Colors.grey.shade700),
                  const SizedBox(height: 8),
                  _iconTextRow(Icons.money,
                      "₹${currencyFormatter.format(trip!.price)} per seat",
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 8),
                  _iconTextRow(
                      Icons.event_seat, "Available Seats: $availableSeats"),
                  const SizedBox(height: 16),

                  // 📝 Itinerary
                  if (trip!.itinerary.isNotEmpty)
                    _buildInfoCard(
                      title: "Itinerary",
                      children: trip!.itinerary
                          .map(
                            (day) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.today,
                                      color: Colors.teal, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Day ${day['day']}: ${day['description']}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  // 🍽 Meals
                  if (trip!.meals.isNotEmpty)
                    _buildInfoCard(
                      title: "Meals",
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu,
                                color: Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(trip!.meals.join(", "),
                                    style: const TextStyle(fontSize: 15))),
                          ],
                        ),
                      ],
                    ),

                  // 🎯 Activities
                  if (trip!.activities.isNotEmpty)
                    _buildInfoCard(
                      title: "Activities",
                      children: trip!.activities
                          .map(
                            (act) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.teal, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(act,
                                        style: const TextStyle(fontSize: 15)),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 24),

                  // ✅ Feedback Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.feedback, color: Colors.teal),
                      label: const Text("Give Feedback",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.teal, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripFeedbackPage(tripId: trip!.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

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
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                      ),
                      child: const Text(
                        "Book Now",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconTextRow(IconData icon, String text,
      {Color color = Colors.teal, FontWeight fontWeight = FontWeight.normal}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: fontWeight),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(String title, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[index],
                    width: 280,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
