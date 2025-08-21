import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip_card.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    tripProvider.fetchTrips();

    return Scaffold(
      appBar: AppBar(title: const Text("Customer Dashboard")),
      body: ListView.builder(
        itemCount: tripProvider.trips.length,
        itemBuilder: (ctx, i) {
          final trip = tripProvider.trips[i];
          return TripCard(
            title: "${trip.source} → ${trip.destination}",
            price: "₹${trip.price}",
            rating: trip.rating,
            onTap: () {},
          );
        },
      ),
    );
  }
}
