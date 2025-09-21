// lib/screens/customer/my_booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip_package.dart';
import '../../models/booking.dart';
import '../trip_feedback_page.dart';
import '../../theme.dart';

class MyBookingDetailsPage extends StatelessWidget {
  final TripPackage trip;
  final Booking booking;

  const MyBookingDetailsPage({
    super.key,
    required this.trip,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final bookDateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.title),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          // Scrollable content
          Padding(
            padding: const EdgeInsets.only(bottom: 70), // space for bottom button
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip main image
                  if (trip.imageUrl != null && trip.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        trip.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Basic Trip Info
                  Text("${trip.source} ➝ ${trip.destination}",
                      style: Theme.of(context)
                          .textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    "${dateFmt.format(trip.startDate)} - ${dateFmt.format(trip.endDate)}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(trip.price)}",
                    style: Theme.of(context)
                        .textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 24),

                  // Trip Gallery
                  if (trip.gallery.isNotEmpty)
                    HorizontalImageGallery(title: "Gallery", images: trip.gallery),

                  // Booking Info
                  InfoSection(
                    title: "Booking Info",
                    children: [
                      Text("Seats: ${booking.seats}"),
                      Text(
                          "Amount Paid: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(booking.amount)}"),
                      Text(
                        "Status: ${booking.status.name.toUpperCase()}",
                        style: TextStyle(
                          color: booking.status == BookingStatus.paid
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Booked On: ${bookDateFmt.format(booking.createdAt)}"),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Trip Description
                  InfoSection(title: "About Trip", children: [Text(trip.description)]),

                  // Hotel Info
                  if (trip.hotelName != null && trip.hotelName!.isNotEmpty)
                    HotelSection(trip: trip),

                  // Meals
                  if (trip.meals.isNotEmpty)
                    ChipsSection(title: "Meals", items: trip.meals),

                  // Activities
                  if (trip.activities.isNotEmpty)
                    ChipsSection(title: "Activities", items: trip.activities),

                  const SizedBox(height: 24),

                  // Airport Pickup
                  Row(
                    children: [
                      const Icon(Icons.airport_shuttle, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(trip.airportPickup
                          ? "Airport Pickup Included"
                          : "No Airport Pickup"),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Itinerary
                  if (trip.itinerary.isNotEmpty)
                    ItinerarySection(itinerary: trip.itinerary),

                  const SizedBox(height: 24),

                  // Travellers
                  if (trip.travellers.isNotEmpty)
                    InfoSection(
                      title: "Travellers",
                      children: trip.travellers
                          .map((t) => ListTile(
                                leading: const Icon(Icons.person, color: AppColors.primary),
                                title: Text(t['name'] ?? 'Unknown'),
                              ))
                          .toList(),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Sticky Feedback Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.feedback),
                  label: const Text("Give Feedback"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripFeedbackPage(tripId: trip.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ Reusable Widgets ------------------

class InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const InfoSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class HorizontalImageGallery extends StatelessWidget {
  final String title;
  final List<String> images;

  const HorizontalImageGallery({super.key, required this.title, required this.images});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                images[i],
                width: 150,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class ChipsSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const ChipsSection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: title,
      children: [
        Wrap(
          spacing: 8,
          children: items.map((item) => Chip(label: Text(item))).toList(),
        ),
      ],
    );
  }
}

class ItinerarySection extends StatelessWidget {
  final List<Map<String, dynamic>> itinerary;

  const ItinerarySection({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: "Itinerary",
      children: itinerary.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final day = item['day'] ?? (index + 1);
        final plan = (item['plan'] as String?)?.trim();
        final meals = (item['meals'] as List<dynamic>?)
            ?.where((e) => (e as String).trim().isNotEmpty)
            .toList();
        final activities = (item['activities'] as List<dynamic>?)
            ?.where((e) => (e as String).trim().isNotEmpty)
            .toList();

        if ((plan == null || plan.isEmpty) &&
            (meals == null || meals.isEmpty) &&
            (activities == null || activities.isEmpty)) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Day $day",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (plan != null && plan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text("Plan:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(plan),
                ],
                if (meals != null && meals.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text("Meals:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 6,
                    children: meals.map((m) => Chip(label: Text(m))).toList(),
                  ),
                ],
                if (activities != null && activities.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text("Activities:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 6,
                    children: activities.map((a) => Chip(label: Text(a))).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class HotelSection extends StatelessWidget {
  final TripPackage trip;

  const HotelSection({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hotel", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text("${trip.hotelName} ⭐${trip.hotelStars ?? '-'}"),
        if (trip.hotelDescription != null && trip.hotelDescription!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(trip.hotelDescription!),
        ],
        if (trip.hotelMainImage != null && trip.hotelMainImage!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(trip.hotelMainImage!,
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
        ],
        if (trip.hotelGallery.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trip.hotelGallery.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  trip.hotelGallery[i],
                  width: 120,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
