import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For Indian currency formatting
import '../models/trip_package.dart';
import '../services/trip_service.dart';

class TripCard extends StatelessWidget {
  final TripPackage trip;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TripCard({
    Key? key,
    required this.trip,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  Future<void> _deleteTrip(BuildContext context) async {
    try {
      await TripService.deleteTrip(trip.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip deleted successfully')),
      );

      if (onDelete != null) onDelete!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete trip: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAgentOwner = user != null && user.uid == trip.createdBy;

    // Format price in Indian currency
    final formattedPrice = NumberFormat.currency(locale: 'en_IN', symbol: '₹')
        .format(trip.price);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: (trip.imageUrl ?? '').isNotEmpty
                      ? Image.network(
                    trip.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child:
                    const Icon(Icons.image, size: 60, color: Colors.grey),
                  ),
                ),

                // Source ➝ Destination & Dates overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${trip.source} ➝ ${trip.destination}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Price tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formattedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Hotel, Stars, Avg Rating
                  Row(
                    children: [
                      const Icon(Icons.hotel, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.hotelName ?? "Hotel info",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trip.hotelStars != null) ...[
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        Text(
                          "${trip.hotelStars}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if (trip.avgRating != null) ...[
                        const Icon(Icons.reviews, size: 14, color: Colors.deepOrange),
                        const SizedBox(width: 2),
                        Text(
                          trip.avgRating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Capacity & booked
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        "Capacity: ${trip.capacity}, Booked: ${trip.bookedSeats}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Activities
                  if ((trip.activities ?? []).isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: trip.activities!
                          .map(
                            (a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),

                  // Edit/Delete buttons for owner
                  if (isAgentOwner && (onEdit != null || onDelete != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal),
                              onPressed: onEdit,
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTrip(context),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
