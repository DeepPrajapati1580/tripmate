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
      for (var i = totalSelectedSeats; i < _nameControllers.length; i++) {
        _nameControllers[i].dispose();
      }
      _nameControllers = _nameControllers.sublist(0, totalSelectedSeats);
    }
  }

  /// Razorpay handlers
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? '';
    try {
      setState(() => _loading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to book.")),
        );
        setState(() => _loading = false);
        return;
      }

      final travellers = List<Map<String, dynamic>>.from(_pendingTravellers);

      debugPrint("✅ Payment success, saving booking...");
      debugPrint("Trip ID: ${widget.trip.id}");
      debugPrint("User ID: ${user.uid}");
      debugPrint("Seats: $totalSelectedSeats");
      debugPrint("Travellers: $travellers");

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

      final tripRef =
      FirebaseFirestore.instance.collection('trip_packages').doc(widget.trip.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(tripRef);
        if (!snapshot.exists) throw Exception("Trip package not found");

        final currentSeats = snapshot['bookedSeats'] ?? 0;
        final currentTravellers = List<Map<String, dynamic>>.from(
          (snapshot['travellers'] ?? []),
        );
        final currentBookedSeatsList = List<int>.from(
          (snapshot['bookedSeatsList'] ?? []),
        );

        final newSeatNumbers = travellers
            .map((t) => t['seatNumber'])
            .whereType<int>()
            .toList();

        transaction.update(tripRef, {
          'bookedSeats': currentSeats + totalSelectedSeats,
          'travellers': currentTravellers + travellers,
          'bookedSeatsList': currentBookedSeatsList + newSeatNumbers,
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Payment successful, booking confirmed!")),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      debugPrint("❌ FirebaseException: ${e.code} - ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Firestore error: ${e.message}")),
        );
      }
    } catch (e, stack) {
      debugPrint("❌ Unknown error: $e");
      debugPrint("Stack: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving booking: $e")),
        );
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
        elevation: 4,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Info Card
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  shadowColor: Colors.grey.shade300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20)),
                            child: widget.trip.imageUrl != null &&
                                widget.trip.imageUrl!.isNotEmpty
                                ? Image.network(
                              widget.trip.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, size: 60),
                            ),
                          ),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.25),
                                  Colors.transparent
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.trip.title,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("Destination: ${widget.trip.destination}",
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                                "Dates: ${widget.trip.startDate.toString().split(' ').first} - ${widget.trip.endDate.toString().split(' ').first}",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade700)),
                            const SizedBox(height: 8),
                            Text("Price per seat: ₹${widget.trip.price}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Room Selection Row with Stepper style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _roomStepper("1-person", _roomsFor1, 1),
                    _roomStepper("2-person", _roomsFor2, 2),
                  ],
                ),

                const SizedBox(height: 24),
                // Traveller Names Horizontal Cards
                if (totalSelectedSeats > 0)
                   SizedBox(
              height: 70, // ⬅ reduced height for mobile-friendliness
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalSelectedSeats,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 140, // ⬅ narrower for mobile
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 3,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: TextField(
                          controller: _nameControllers[index],
                          decoration: InputDecoration(
                            labelText: "Traveller ${index + 1}",
                            isDense: true, // ⬅ compact input
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 20),
                // Book & Pay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onBookAndPayPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    child: Text(
                      totalSelectedSeats == 0
                          ? "Book & Pay"
                          : "Book & Pay ₹${widget.trip.price * totalSelectedSeats}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay with blur effect
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.teal),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roomStepper(String label, int value, int occupancy) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 5,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _decrementRooms(occupancy),
                icon: const Icon(Icons.remove, color: Colors.red),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("$value",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => _incrementRooms(occupancy),
                icon: const Icon(Icons.add, color: Colors.green),
              ),
            ],
          ),
        ),
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

    _pendingTravellers = List.generate(totalSelectedSeats, (i) {
      final name = _nameControllers[i].text.trim();
      return {
        'seatNumber': i + 1,
        'name': name.isEmpty ? 'Guest ${i + 1}' : name,
      };
    });

    final options = {
      'key': 'rzp_test_RGhdz5pB4jl1PO',
      'amount': widget.trip.price * totalSelectedSeats * 100,
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
