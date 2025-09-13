// lib/pages/customer/trip_list_page.dart
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/trip_package.dart';
import '../../services/trip_service.dart';
import '../../services/payment_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/trip_card.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  final _razorpay = Razorpay();
  int _seats = 1;
  String? _pendingBookingId;
  String? _pendingTripId;
  int _pendingSeatsCount = 0;

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingId != null) {
      await BookingService.markPaid(
        bookingId: _pendingBookingId!,
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful ✅')),
        );
        setState(() {
          _pendingBookingId = null;
          _pendingTripId = null;
          _pendingSeatsCount = 0;
          _seats = 1;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.code}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  Future<void> _startCheckout(TripPackage trip) async {
    final available = trip.capacity - trip.bookedSeatsList.length;
    if (_seats <= 0 || _seats > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $available seats available')),
      );
      setState(() => _seats = available);
      return;
    }

    final totalAmount = trip.price * _seats;

    try {
      final order = await PaymentService.createRazorpayOrder(
        amount: totalAmount,
        currency: 'INR',
        receipt: 'trip_${trip.id}_${DateTime.now().millisecondsSinceEpoch}',
        notes: {'tripPackageId': trip.id},
      );

      final booking = await BookingService.createPendingBooking(
        tripPackageId: trip.id,
        seats: _seats,
        amount: totalAmount,
        razorpayOrderId: order['id'] as String,
      );

      setState(() {
        _pendingBookingId = booking.id;
        _pendingTripId = trip.id;
        _pendingSeatsCount = _seats;
      });

      var options = {
        'key': order['key'] ?? 'rzp_test_xxxxxx',
        'amount': totalAmount,
        'currency': 'INR',
        'name': 'TripMate',
        'description': trip.title,
        'order_id': order['id'],
      };
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout error: $e')),
        );
      }
    }
  }

  void _showBookingModal(TripPackage trip) {
    final available = trip.capacity - trip.bookedSeatsList.length;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text(
                  'Book Seats for "${trip.title}"',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Available Seats: $available',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: available <= 0
                          ? null
                          : () => setState(() {
                        _seats = _seats > 1 ? _seats - 1 : 1;
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_seats',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: available <= 0
                          ? null
                          : () => setState(() {
                        _seats = (_seats + 1).clamp(1, available);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: available <= 0 ? null : () {
                      Navigator.pop(context);
                      _startCheckout(trip);
                    },
                    child: const Text(
                      'Book & Pay',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<TripPackage>>(
        stream: TripService.streamAllTrips(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('No trips available'));
          }

          final trips = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Column(
                children: [
                  TripCard(
                    trip: trip,
                    onTap: () => _showBookingModal(trip),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
