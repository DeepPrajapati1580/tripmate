// lib/widgets/trip_card.dart
import 'package:flutter/material.dart';
import '../models/trip_package.dart';

class TripCard extends StatelessWidget {
  final TripPackage trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            if (trip.imageUrl != null && trip.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(trip.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ListTile(
              title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${trip.destination} • ₹${trip.price}'),
            ),
          ],
        ),
      ),
    );
  }
}
