import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_package.dart';

class TripService {
  static final _col = FirebaseFirestore.instance.collection('trip_packages');
  static final _bookings = FirebaseFirestore.instance.collection('bookings');

  /// ✅ Stream trips created by a specific agent
  static Stream<List<TripPackage>> streamByAgent(
      String agentId, {
        bool onlyUpcoming = false,
      }) {
    Query<Map<String, dynamic>> query =
    _col.where('createdBy', isEqualTo: agentId);

    if (onlyUpcoming) {
      query = query.where('endDate',
          isGreaterThan: Timestamp.fromDate(DateTime.now()));
    }

    return query.snapshots().map(
            (snap) => snap.docs.map((doc) => TripPackage.fromDoc(doc)).toList());
  }

  /// ✅ Stream all trips for customers
  static Stream<List<TripPackage>> streamAllTrips({bool onlyUpcoming = false}) {
    Query<Map<String, dynamic>> query = _col;

    if (onlyUpcoming) {
      query = query.where('endDate',
          isGreaterThan: Timestamp.fromDate(DateTime.now()));
    }

    return query.snapshots().map(
            (snap) => snap.docs.map((doc) => TripPackage.fromDoc(doc)).toList());
  }

  /// ✅ Create new trip
  static Future<void> create({
    required String title,
    required String description,
    required String source,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int price,
    required int capacity,
    required String createdBy,
    String? imageUrl,
    String? imagePublicId,
    List<String>? gallery,
    String? hotelName,
    String? hotelDescription,
    String? hotelMainImage,
    List<String>? hotelGallery,
    int? hotelStars,
    List<String>? meals,
    List<String>? activities,
    bool airportPickup = false,
    List<Map<String, dynamic>>? itinerary,
  }) async {
    await _col.add({
      'title': title,
      'description': description,
      'source': source,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'capacity': capacity,
      'bookedSeats': 0,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'gallery': gallery ?? [],
      'hotelName': hotelName,
      'hotelDescription': hotelDescription,
      'hotelMainImage': hotelMainImage,
      'hotelGallery': hotelGallery ?? [],
      'hotelStars': hotelStars,
      'meals': meals ?? [],
      'activities': activities ?? [],
      'airportPickup': airportPickup,
      'itinerary': itinerary ?? [],
      'travellers': <Map<String, dynamic>>[],
    });
  }

  /// ✅ Update existing trip
  static Future<void> update({
    required String tripId,
    String? title,
    String? description,
    String? source,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? price,
    int? capacity,
    String? imageUrl,
    String? imagePublicId,
    List<String>? gallery,
    String? hotelName,
    String? hotelDescription,
    String? hotelMainImage,
    List<String>? hotelGallery,
    int? hotelStars,
    List<String>? meals,
    List<String>? activities,
    bool? airportPickup,
    List<Map<String, dynamic>>? itinerary,
    List<Map<String, dynamic>>? travellers,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (source != null) updates['source'] = source;
    if (destination != null) updates['destination'] = destination;
    if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
    if (price != null) updates['price'] = price;
    if (capacity != null) updates['capacity'] = capacity;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (imagePublicId != null) updates['imagePublicId'] = imagePublicId;
    if (gallery != null) updates['gallery'] = gallery;
    if (hotelName != null) updates['hotelName'] = hotelName;
    if (hotelDescription != null) {
      updates['hotelDescription'] = hotelDescription;
    }
    if (hotelMainImage != null) updates['hotelMainImage'] = hotelMainImage;
    if (hotelGallery != null) updates['hotelGallery'] = hotelGallery;
    if (hotelStars != null) updates['hotelStars'] = hotelStars;
    if (meals != null) updates['meals'] = meals;
    if (activities != null) updates['activities'] = activities;
    if (airportPickup != null) updates['airportPickup'] = airportPickup;
    if (itinerary != null) updates['itinerary'] = itinerary;
    if (travellers != null) updates['travellers'] = travellers;

    await _col.doc(tripId).update(updates);
  }

  /// ✅ Book trip with traveller details
  static Future<void> bookTrip({
    required String tripId,
    required List<Map<String, dynamic>> travellers,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("You must be logged in");

    final tripRef = _col.doc(tripId);

    try {
      // Run transaction
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snapshot = await txn.get(tripRef);
        if (!snapshot.exists) throw Exception("Trip not found");

        final data = snapshot.data() as Map<String, dynamic>;
        final bookedSeats = (data['bookedSeats'] as num?)?.toInt() ?? 0;
        final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
        final availableSeats = (data['availableSeats'] as num?)
            ?.toInt() ??
            (capacity - bookedSeats);

        if (travellers.length > availableSeats) {
          throw Exception("Not enough seats available");
        }

        // Merge travellers
        final existingTravellers = List<Map<String, dynamic>>.from(data['travellers'] ?? []);
        final updatedTravellers = [...existingTravellers, ...travellers];

        // Update trip document
        txn.update(tripRef, {
          'bookedSeats': bookedSeats + travellers.length,
          'availableSeats': availableSeats - travellers.length,
          'travellers': updatedTravellers,
        });
      });

      // Fetch trip price
      final tripSnapshot = await tripRef.get();
      final tripData = tripSnapshot.data() as Map<String, dynamic>;
      final price = (tripData['price'] as num?)?.toInt() ?? 0;

      // Add booking record (status: pending or paid after Razorpay success)
      await _bookings.add({
        'tripPackageId': tripId,
        'userId': user.uid,
        'travellers': travellers,
        'seats': travellers.length,
        'amount': travellers.length * price,
        'status': 'paid', // mark as paid only after Razorpay success
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Booking failed: $e");
      rethrow;
    }
  }

  /// Stream trips created by a specific agent
  static Stream<List<TripPackage>> streamTripsByAgent(String agentId) {
    final query = _col
        .where('createdBy', isEqualTo: agentId)
        .orderBy('startDate', descending: false);

    return query.snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => TripPackage.fromDoc(doc)).toList());
  }

  /// Fetch trips by agent (one-time)
  static Future<List<TripPackage>> fetchTripsByAgent(String agentId) async {
    final querySnap = await _col
        .where('createdBy', isEqualTo: agentId)
        .orderBy('startDate', descending: false)
        .get();

    return querySnap.docs.map((doc) => TripPackage.fromDoc(doc)).toList();
  }

  /// ✅ Get all trips
  static Stream<QuerySnapshot<Map<String, dynamic>>> getTrips() =>
      _col.snapshots();

  /// ✅ Get one trip
  static Future<DocumentSnapshot<Map<String, dynamic>>> getTrip(String id) =>
      _col.doc(id).get();

  /// ✅ Cancel all bookings of a specific user for a specific trip
  static Future<void> cancelUserBookingsForTrip(String tripId, String userId) async {
    final tripRef = _col.doc(tripId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final tripSnap = await txn.get(tripRef);
      if (!tripSnap.exists) throw Exception("Trip not found");

      final tripData = tripSnap.data() as Map<String, dynamic>;
      final existingTravellers = List<Map<String, dynamic>>.from(tripData['travellers'] ?? []);
      var bookedSeats = (tripData['bookedSeats'] as num?)?.toInt() ?? 0;

      // Fetch all bookings for this trip by this user
      final bookingsQuery = await _bookings
          .where('tripPackageId', isEqualTo: tripId)
          .where('userId', isEqualTo: userId)
          .get();

      for (var bookingSnap in bookingsQuery.docs) {
        final bookingData = bookingSnap.data();
        final travellers = List<Map<String, dynamic>>.from(bookingData['travellers'] ?? []);
        final seats = (bookingData['seats'] as num?)?.toInt() ?? travellers.length;

        // Remove travellers of this booking from the trip's travellers list
        for (var t in travellers) {
          existingTravellers.removeWhere((et) => et['seatNumber'] == t['seatNumber'] && et['name'] == t['name']);
        }

        // Decrement bookedSeats safely
        bookedSeats = (bookedSeats - seats).clamp(0, bookedSeats);

        // Delete the booking itself
        txn.delete(bookingSnap.reference);
      }

      // Update trip with new bookedSeats and travellers
      txn.update(tripRef, {
        'bookedSeats': bookedSeats,
        'travellers': existingTravellers,
      });
    });
  }

  static Future<void> deleteTrip(String tripId) async {
    final tripRef = _col.doc(tripId);
    final bookingsQuery = _bookings.where('tripPackageId', isEqualTo: tripId);

    final feedbacksQuery = FirebaseFirestore.instance
        .collection('feedback')
        .where('tripId', isEqualTo: tripId);

    // Firestore batch for atomic operations
    final batch = FirebaseFirestore.instance.batch();

    try {
      // 1. Delete all bookings related to the trip
      final bookingsSnapshot = await bookingsQuery.get();
      for (final bookingDoc in bookingsSnapshot.docs) {
        batch.delete(bookingDoc.reference);
      }

      // 2. Delete all feedback related to the trip
      final feedbackSnapshot = await feedbacksQuery.get();
      for (final feedbackDoc in feedbackSnapshot.docs) {
        batch.delete(feedbackDoc.reference);
      }

      // 3. Delete the trip document itself
      batch.delete(tripRef);

      // Commit batch
      await batch.commit();

    } catch (e) {
      print("❌ Error deleting trip and related data: $e");
      rethrow;
    }
  }

}
