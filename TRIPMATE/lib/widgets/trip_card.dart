import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class TripCard extends StatelessWidget {
  final TripPackage trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            if (trip.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(trip.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ListTile(
              title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${trip.destination} • ₹${trip.pricePerSeat ~/ 100}"),
            ),
          ],
        ),
      ),
    );
  }
}
