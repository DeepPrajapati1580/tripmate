// lib/screens/customer/trip_booking_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/trip_package.dart';

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
  late Razorpay _razorpay;
  List<Map<String, dynamic>> _pendingTravellers = [];

  int get totalSelectedSeats => _roomsFor1 * 1 + _roomsFor2 * 2;

  int get availableSeats =>
      widget.trip.capacity - (widget.trip.bookedSeatsList?.length ?? 0);

  @override
  void initState() {
    super.initState();
    _nameControllers = [];
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    _razorpay.clear();
    super.dispose();
  }

  void _updateControllers() {
    if (_nameControllers.length < totalSelectedSeats) {
      _nameControllers.addAll(List.generate(
          totalSelectedSeats - _nameControllers.length,
          (_) => TextEditingController()));
    } else if (_nameControllers.length > totalSelectedSeats) {
      // dispose the removed controllers to avoid leaks
      for (var i = totalSelectedSeats; i < _nameControllers.length; i++) {
        _nameControllers[i].dispose();
      }
      _nameControllers = _nameControllers.sublist(0, totalSelectedSeats);
    }
  }

  /// Razorpay handlers
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    // response.paymentId, response.orderId, response.signature
    final paymentId = response.paymentId ?? '';
    try {
      setState(() => _loading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You must be logged in to book.")));
        setState(() => _loading = false);
        return;
      }

      // Use the prepared _pendingTravellers (set before opening checkout)
      final travellers = List<Map<String, dynamic>>.from(_pendingTravellers);

      // Create booking doc in Firestore
      await FirebaseFirestore.instance.collection('bookings').add({
        'tripPackageId': widget.trip.id,
        'userId': user.uid,
        'seats': totalSelectedSeats,
        'amount': widget.trip.price * totalSelectedSeats,
        'travellers': travellers,
        'paymentId': paymentId,
        'status': 'PAID',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Optionally: update trip package booked seats or counters here if needed.

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment successful ✅ Booking confirmed")));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error saving booking: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    final message = response.message ?? 'Unknown error';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Payment failed ❌ $message")));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    final walletName = response.walletName ?? 'external wallet';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("External Wallet: $walletName")));
  }

  @override
  Widget build(BuildContext context) {
    _updateControllers();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.title),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      onPressed: _loading ? null : _onBookAndPayPressed,
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

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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

  Future<void> _onBookAndPayPressed() async {
    if (totalSelectedSeats == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select seats before payment")),
      );
      return;
    }

    if (totalSelectedSeats > availableSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough seats available")),
      );
      return;
    }

    // Prepare travellers list and store it so the payment handler can use it
    _pendingTravellers = List.generate(totalSelectedSeats, (i) {
      final name = _nameControllers[i].text.trim();
      return {
        'seatNumber': i + 1,
        'name': name.isEmpty ? 'Guest ${i + 1}' : name,
      };
    });

    // Open Razorpay checkout directly.
    // NOTE: Replace 'rzp_test_yourkey' with your actual Razorpay key.
    final options = {
      'key': 'rzp_test_RGhdz5pB4jl1PO', // <-- put your key here
      'amount': widget.trip.price * totalSelectedSeats * 100, // in paise
      'name': widget.trip.title,
      'description': 'Booking for ${widget.trip.title} ($totalSelectedSeats seats)',
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
      },
      'theme': {'color': '#009688'},
    };

    try {
      setState(() => _loading = true);
      _razorpay.open(options);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error launching payment: $e")));
    }
  }
}
