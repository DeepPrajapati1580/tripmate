import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip_package.dart';
import '../../models/booking.dart';
import '../../widgets/itinerary_day_widget.dart';

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
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Trip main image
            if (trip.imageUrl != null && trip.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  trip.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            /// Basic Trip Info
            Text("${trip.source} ➝ ${trip.destination}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              "${dateFmt.format(trip.startDate)} - ${dateFmt.format(trip.endDate)}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text("₹${trip.price}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const Divider(height: 32),

            /// Trip Gallery
            if (trip.gallery.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Gallery",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trip.gallery.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      trip.gallery[i],
                      width: 150,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
            ],

            /// Booking Info
            Text("Booking Info",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Seats: ${booking.seats}"),
                    Text("Amount Paid: ₹${booking.amount}"),
                    Text(
                      "Status: ${booking.status.name.toUpperCase()}",
                      style: TextStyle(
                        color: booking.status == BookingStatus.paid
                            ? Colors.green
                            : (booking.status == BookingStatus.pending ? Colors.orange : Colors.red),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Booked On: ${bookDateFmt.format(booking.createdAt)}"),
                  ],
                ),
              ),
            ),

            const Divider(height: 32),

            /// Trip Description
            Text("About Trip",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(trip.description),

            const Divider(height: 32),

            /// Hotel Info
            if (trip.hotelName != null && trip.hotelName!.isNotEmpty) ...[
              Text("Hotel",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                  child: Image.network(trip.hotelMainImage!, height: 180, fit: BoxFit.cover),
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
              const Divider(height: 32),
            ],

            /// Meals
            if (trip.meals.isNotEmpty) ...[
              Text("Meals",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: trip.meals.map((m) => Chip(label: Text(m))).toList()),
              const Divider(height: 32),
            ],

            /// Activities
            if (trip.activities.isNotEmpty) ...[
              Text("Activities",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: trip.activities.map((a) => Chip(label: Text(a))).toList()),
              const Divider(height: 32),
            ],

            /// Airport Pickup
            Row(
              children: [
                const Icon(Icons.airport_shuttle, color: Colors.teal),
                const SizedBox(width: 8),
                Text(trip.airportPickup ? "Airport Pickup Included" : "No Airport Pickup"),
              ],
            ),
            const Divider(height: 32),

            /// Itinerary (using ItineraryDayField in read-only mode)
            /// Itinerary
            if (trip.itinerary.isNotEmpty) ...[
              Text("Itinerary",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: trip.itinerary.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  final day = item['day'] ?? (index + 1);
                  final plan = (item['plan'] as String?)?.trim();
                  final meals = (item['meals'] as List<dynamic>?)?.where((e) => (e as String).trim().isNotEmpty).toList();
                  final activities = (item['activities'] as List<dynamic>?)?.where((e) => (e as String).trim().isNotEmpty).toList();

                  // Skip completely empty items
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
                          Text("Day $day", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                          // Description / Plan
                          if (plan != null && plan.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text("Plan:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(plan),
                          ],

                          // Meals
                          if (meals != null && meals.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text("Meals:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 6,
                              children: meals.map((m) => Chip(label: Text(m))).toList(),
                            ),
                          ],

                          // Activities
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
              ),
              const Divider(height: 32),
            ],
            /// Travellers
            if (trip.travellers.isNotEmpty) ...[
              Text("Travellers",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: trip.travellers.map((t) {
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: Text(t['name'] ?? 'Unknown'),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
