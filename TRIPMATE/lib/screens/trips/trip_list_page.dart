// lib/pages/customer/trip_list_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/trip_package.dart';
import '../../services/trip_service.dart';
import '../../services/payment_service.dart';
import '../../services/booking_service.dart';

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
      // ✅ mark booking as paid
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
    final available = trip.capacity - (trip.bookedSeatsList?.length ?? 0);
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

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Available Trips')),
      body: StreamBuilder<List<TripPackage>>(
        stream: TripService.streamAllTrips(), // Updated method to return Stream<List<TripPackage>>
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('No trips available'));
          }

          final trips = snap.data!;
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final bookedSeats = trip.bookedSeatsList?.length ?? 0;
              final available = trip.capacity - bookedSeats;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                          '${trip.destination} • ${dateFmt.format(trip.startDate)} - ${dateFmt.format(trip.endDate)}'),
                      const SizedBox(height: 6),
                      Text(trip.description,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Text('Available: $available / ${trip.capacity}'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text('₹ ${trip.price} per seat'),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: available <= 0
                                    ? null
                                    : () => setState(() {
                                  _seats = _seats > 1 ? _seats - 1 : 1;
                                }),
                              ),
                              Text('$_seats'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: available <= 0
                                    ? null
                                    : () => setState(() {
                                  _seats =
                                      (_seats + 1).clamp(1, available);
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                          available <= 0 ? null : () => _startCheckout(trip),
                          child: const Text('Book & Pay'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
