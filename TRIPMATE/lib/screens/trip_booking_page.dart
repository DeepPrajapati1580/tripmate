// lib/screens/customer/trip_booking_page.dart
import 'package:flutter/material.dart';
import '../../models/trip_package.dart';
import '../../services/trip_service.dart';

class TripBookingPage extends StatefulWidget {
  final TripPackage trip;
  const TripBookingPage({super.key, required this.trip});

  @override
  State<TripBookingPage> createState() => _TripBookingPageState();
}

class _TripBookingPageState extends State<TripBookingPage> {
  int _seats = 1;
  bool _loading = false;

  Future<void> _bookTrip() async {
    if (_seats <= 0) return;
    setState(() => _loading = true);

    try {
      await TripService.bookTrip(
        widget.trip.id ?? "",                // trip id
        _seats,                              // seats
        widget.trip.pricePerSeat ?? 0,       // price per seat
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking confirmed ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.trip.capacity - widget.trip.bookedSeats;
    return Scaffold(
      appBar: AppBar(title: Text("Book ${widget.trip.title}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trip.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(widget.trip.description),
            const SizedBox(height: 20),
            Text("Seats Available: $available"),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Seats: "),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                  _seats > 1 ? () => setState(() => _seats--) : null,
                ),
                Text("$_seats"),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _seats < available
                      ? () => setState(() => _seats++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Total: ₹ ${(widget.trip.pricePerSeat / 100 * _seats).toStringAsFixed(0)}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _bookTrip,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirm Booking"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
