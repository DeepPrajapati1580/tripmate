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
  final Set<int> _selectedSeats = {};
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
      appBar: AppBar(
        title: Text(widget.trip.title),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 🟢 Trip Info Header
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.trip.imageUrl != null && widget.trip.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.trip.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    widget.trip.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Destination: ${widget.trip.destination}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Dates: ${widget.trip.startDate} - ${widget.trip.endDate}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Price per seat: ₹${widget.trip.price}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Available Seats: ${totalSeats - bookedSeatsList.length}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_selectedSeats.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Selected Seats: ${_selectedSeats.join(', ')}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select your seats:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ✅ Seat Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: totalSeats,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
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
                    textColor = Colors.white;
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                        boxShadow: [
                          if (!isBooked)
                            const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(1, 1))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "$seatNo",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ✅ Book Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _bookSeats,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _selectedSeats.isEmpty
                      ? "Book Now"
                      : "Book ${_selectedSeats.length} Seat(s)",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
