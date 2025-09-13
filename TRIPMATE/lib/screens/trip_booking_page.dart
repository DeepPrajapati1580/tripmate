// lib/screens/customer/trip_booking_page.dart
import 'package:flutter/material.dart';
import '../../models/trip_package.dart';
import '../../services/booking_service.dart';
import '../../services/razorpay_service.dart'; // 👈 added

class TripBookingPage extends StatefulWidget {
  final TripPackage trip;
  const TripBookingPage({super.key, required this.trip});

  @override
  State<TripBookingPage> createState() => _TripBookingPageState();
}

class _TripBookingPageState extends State<TripBookingPage> {
  int _roomsFor1 = 0;
  int _roomsFor2 = 0;
  bool _loading = false;
  late List<TextEditingController> _nameControllers;

  int get totalSelectedSeats => _roomsFor1 * 1 + _roomsFor2 * 2;

  int get availableSeats =>
      widget.trip.capacity - widget.trip.bookedSeatsList.length;

  @override
  void initState() {
    super.initState();
    _nameControllers = [];
    RazorpayService.init(context); // 👈 init Razorpay
  }

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    RazorpayService.dispose(); // 👈 clear listeners
    super.dispose();
  }

  void _updateControllers() {
    if (_nameControllers.length < totalSelectedSeats) {
      _nameControllers.addAll(List.generate(
          totalSelectedSeats - _nameControllers.length,
          (_) => TextEditingController()));
    } else if (_nameControllers.length > totalSelectedSeats) {
      _nameControllers = _nameControllers.sublist(0, totalSelectedSeats);
    }
  }

  Future<void> _bookRooms() async {
    if (totalSelectedSeats == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one room")),
      );
      return;
    }

    if (totalSelectedSeats > availableSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Only $availableSeats seats available, reduce your selection")),
      );
      return;
    }

    _updateControllers();

    for (var i = 0; i < _nameControllers.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enter name for traveller ${i + 1}")),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final travellers = List.generate(totalSelectedSeats, (i) => {
            'seatNumber': i + 1,
            'name': _nameControllers[i].text.trim(),
          });

      await BookingService.createPendingBooking(
        tripPackageId: widget.trip.id,
        seats: totalSelectedSeats,
        amount: widget.trip.price * totalSelectedSeats,
        travellers: travellers,
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

  void _incrementRooms(int occupancy) {
    setState(() {
      if (occupancy == 1 && totalSelectedSeats + 1 <= availableSeats) {
        _roomsFor1++;
      } else if (occupancy == 2 && totalSelectedSeats + 2 <= availableSeats) {
        _roomsFor2++;
      }
    });
  }

  void _decrementRooms(int occupancy) {
    setState(() {
      if (occupancy == 1 && _roomsFor1 > 0) _roomsFor1--;
      if (occupancy == 2 && _roomsFor2 > 0) _roomsFor2--;
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateControllers();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.title),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Info
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.trip.imageUrl != null &&
                        widget.trip.imageUrl!.isNotEmpty)
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
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Destination: ${widget.trip.destination}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                        "Dates: ${widget.trip.startDate.toString().split(' ').first} - ${widget.trip.endDate.toString().split(' ').first}",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text("Price per seat: ₹${widget.trip.price}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text("Available Seats: $availableSeats",
                        style: const TextStyle(fontSize: 16)),
                    if (totalSelectedSeats > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Selected Seats: $totalSelectedSeats",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.green),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Room Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roomSelector(
                    "1-person", _roomsFor1, _incrementRooms, _decrementRooms, 1),
                _roomSelector(
                    "2-person", _roomsFor2, _incrementRooms, _decrementRooms, 2),
              ],
            ),

            const SizedBox(height: 16),
            // Traveller Names
            if (totalSelectedSeats > 0)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalSelectedSeats,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _nameControllers[index],
                          decoration: InputDecoration(
                            labelText: "Traveller ${index + 1}",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // --- Book & Pay Button ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (totalSelectedSeats == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Select seats before payment")),
                      );
                      return;
                    }

                    try {
                      final order = await RazorpayService.createOrder(
                        amount: widget.trip.price * totalSelectedSeats,
                        receipt: 'trip_${widget.trip.id}',
                      );

                      await RazorpayService.openCheckout(
                        amount: widget.trip.price * totalSelectedSeats,
                        orderId: order?['id'],
                        name: widget.trip.title,
                        description:
                            'Booking for ${widget.trip.title} ($totalSelectedSeats seats)',
                        prefill: {
                          'contact': '', // fill from logged-in user if available
                          'email': '',
                        },
                      );
                    } catch (e) {
                      await RazorpayService.openCheckout(
                        amount: widget.trip.price * totalSelectedSeats,
                        name: widget.trip.title,
                        description:
                            'Booking for ${widget.trip.title} ($totalSelectedSeats seats)',
                        prefill: {
                          'contact': '',
                          'email': '',
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    totalSelectedSeats == 0
                        ? "Book & Pay"
                        : "Book & Pay ₹${widget.trip.price * totalSelectedSeats}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomSelector(String label, int value,
      void Function(int) onIncrement, void Function(int) onDecrement, int occupancy) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
                onPressed: () => onDecrement(occupancy),
                icon: const Icon(Icons.remove_circle_outline)),
            Text("$value", style: const TextStyle(fontSize: 18)),
            IconButton(
                onPressed: () => onIncrement(occupancy),
                icon: const Icon(Icons.add_circle_outline)),
          ],
        )
      ],
    );
  }
}
