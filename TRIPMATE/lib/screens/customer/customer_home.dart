import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip_card.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  @override
  void initState() {
    super.initState();
    // Fetch trips only once when the screen loads
    Future.microtask(() =>
        Provider.of<TripProvider>(context, listen: false).fetchTrips());
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Customer Dashboard")),
      body: tripProvider.trips.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: tripProvider.trips.length,
        itemBuilder: (ctx, i) {
          final trip = tripProvider.trips[i];
          return TripCard(
            trip: trip, // ✅ pass the whole TripPackage object
            onTap: () {
              // TODO: navigate to trip details
            },
          );
        },
      ),
    );
  }
}
