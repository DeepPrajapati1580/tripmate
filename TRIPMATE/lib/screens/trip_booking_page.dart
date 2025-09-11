// lib/screens/customer/trip_booking_page.dart
import 'package:flutter/material.dart';
import 'package:tripmate/models/trip_package.dart';
import 'package:tripmate/services/trip_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripBookingPage extends StatefulWidget {
  final TripPackage trip;
  const TripBookingPage({super.key, required this.trip});

  @override
  State<TripBookingPage> createState() => _TripBookingPageState();
}

class _TripBookingPageState extends State<TripBookingPage> {
  final Set<int> _selectedSeats = {};
  bool _loading = false;
  late List<TextEditingController> _nameControllers;

  @override
  void initState() {
    super.initState();
    _nameControllers = [];
  }

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateControllers() {
    if (_nameControllers.length < _selectedSeats.length) {
      _nameControllers.addAll(List.generate(
          _selectedSeats.length - _nameControllers.length,
              (_) => TextEditingController()));
    } else if (_nameControllers.length > _selectedSeats.length) {
      _nameControllers = _nameControllers.sublist(0, _selectedSeats.length);
    }
  }

  Future<void> _bookSeats() async {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one seat")),
      );
      return;
    }

    _updateControllers();

    // Validate names
    for (var i = 0; i < _nameControllers.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a name for seat ${_selectedSeats.elementAt(i)}")),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final travellers = List.generate(
        _selectedSeats.length,
            (index) => {
          'name': _nameControllers[index].text.trim(),
          'seatNumber': _selectedSeats.elementAt(index),
        },
      );

      await TripService.bookTrip(
        tripId: widget.trip.id,
        travellers: travellers,
        userId: FirebaseAuth.instance.currentUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking successful ✅")),
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
    final totalSeats = widget.trip.capacity;
    final bookedSeatsList = widget.trip.bookedSeatsList ?? [];
    final availableSeats = totalSeats - bookedSeatsList.length;
    _updateControllers();

    // Calculate seats per row based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final seatSize = 50.0; // Width & height of each seat box
    final crossAxisCount = screenWidth ~/ (seatSize + 8); // Add spacing
    final crossAxisCountFinal = crossAxisCount > 0 ? crossAxisCount : 5;

    return Scaffold(
      appBar: AppBar(title: Text(widget.trip.title), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Trip Info
            Card(
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
                    Text(widget.trip.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Destination: ${widget.trip.destination}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text("Dates: ${widget.trip.startDate} - ${widget.trip.endDate}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text("Price per seat: ₹${widget.trip.price}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text("Available Seats: $availableSeats", style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select your seats:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // Responsive Seat Grid
            Expanded(
              child: GridView.builder(
                itemCount: totalSeats,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCountFinal,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
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
                        } else if (_selectedSeats.length < availableSeats) {
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
                          if (!isBooked) const BoxShadow(
                              color: Colors.black12, blurRadius: 2, offset: Offset(1, 1))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "$seatNo",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Traveller Names
            if (_selectedSeats.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Enter Traveller Names:", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedSeats.length,
                  itemBuilder: (context, index) {
                    final seatNo = _selectedSeats.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _nameControllers[index],
                          decoration: InputDecoration(
                            labelText: "Seat $seatNo",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Book Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }
}
