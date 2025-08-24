import 'package:flutter/material.dart';
import 'package:tripmate/models/trip_package.dart';
import 'package:tripmate/services/trip_service.dart';

class TripDetailsPage extends StatefulWidget {
  final TripPackage trip;
  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int _seatsToBook = 1;
  bool _loading = false;

  Future<void> _bookSeats() async {
    setState(() => _loading = true);
    try {
      final amount = _seatsToBook * widget.trip.pricePerSeat;
      await TripService.createBooking(
        tripId: widget.trip.id,
        seats: _seatsToBook,
        amount: amount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking created successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.trip.capacity - widget.trip.bookedSeats;

    return Scaffold(
      appBar: AppBar(title: Text(widget.trip.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trip.description),
            const SizedBox(height: 16),
            Text("Available Seats: $available"),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Seats: "),
                DropdownButton<int>(
                  value: _seatsToBook,
                  items: List.generate(
                    available,
                        (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text("${i + 1}"),
                    ),
                  ),
                  onChanged: (val) => setState(() => _seatsToBook = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _bookSeats,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Book Now"),
            )
          ],
        ),
      ),
    );
  }
}
