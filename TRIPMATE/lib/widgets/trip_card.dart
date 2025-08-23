// lib/widgets/trip_card.dart
import 'package:flutter/material.dart';
import '../models/trip_package.dart';
import 'package:intl/intl.dart';

class TripCard extends StatelessWidget {
  final TripPackage trip;
  final VoidCallback? onTap;

  const TripCard({super.key, required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: trip.imageUrl != null ? Image.network(trip.imageUrl!, width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.flight_takeoff),
        title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${trip.destination}\n${df.format(trip.startDate)} → ${df.format(trip.endDate)} • ₹${trip.price}'),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}
