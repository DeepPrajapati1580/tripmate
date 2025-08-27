// lib/screens/trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:tripmate/models/trip_package.dart';
import 'package:tripmate/services/trip_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripDetailsPage extends StatefulWidget {
  final TripPackage trip;
  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  Set<int> _selectedSeats = {};
  bool _loading = false;

  Future<void> _bookSeats() async {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one seat")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await TripService.bookTrip(
        tripId: widget.trip.id,
        seats: _selectedSeats.toList(),
        userId: FirebaseAuth.instance.currentUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Seats booked successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSeats = widget.trip.capacity;
    final bookedSeatsList = widget.trip.bookedSeatsList ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.trip.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.trip.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text("Destination: ${widget.trip.destination}"),
            Text("Dates: ${widget.trip.startDate} - ${widget.trip.endDate}"),
            const SizedBox(height: 16),
            Text("Available Seats: ${totalSeats - bookedSeatsList.length}"),
            const SizedBox(height: 16),

            // ✅ Seat grid UI
            Expanded(
              child: GridView.builder(
                itemCount: totalSeats,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final seatNo = index + 1;
                  final isBooked = bookedSeatsList.contains(seatNo);
                  final isSelected = _selectedSeats.contains(seatNo);

                  Color bgColor;
                  Color textColor;

                  if (isBooked) {
                    bgColor = Colors.grey.shade400;
                    textColor = Colors.white;
                  } else if (isSelected) {
                    bgColor = Colors.green;
                    textColor = Colors.black; // ✅ black text for selected
                  } else {
                    bgColor = Colors.white;
                    textColor = Colors.black;
                  }

                  return GestureDetector(
                    onTap: isBooked
                        ? null
                        : () {
                      setState(() {
                        if (isSelected) {
                          _selectedSeats.remove(seatNo);
                        } else {
                          _selectedSeats.add(seatNo);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black54),
                      ),
                      child: Center(
                        child: Text(
                          "$seatNo",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _bookSeats,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Book Now"),
            )
          ],
        ),
      ),
    );
  }
}
