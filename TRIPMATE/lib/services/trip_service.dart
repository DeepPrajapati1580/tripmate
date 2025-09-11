import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_package.dart';

class TripService {
  static final _col = FirebaseFirestore.instance.collection('trip_packages');


  /// ✅ Stream trips created by a specific agent
  static Stream<List<TripPackage>> streamByAgent(
      String agentId, {
        bool onlyUpcoming = false,
      }) {
    Query<Map<String, dynamic>> query =
    _col.where('createdBy', isEqualTo: agentId);

    // Filter only upcoming trips
    if (onlyUpcoming) {
      query = query.where('endDate',
          isGreaterThan: Timestamp.fromDate(DateTime.now()));
    }

    return query.snapshots().map(
          (snap) => snap.docs.map((doc) => TripPackage.fromDoc(doc)).toList(),
    );
  }

  /// ✅ Stream all trips for customers
  static Stream<List<TripPackage>> streamAllTrips({bool onlyUpcoming = false}) {
    Query<Map<String, dynamic>> query = _col;

    if (onlyUpcoming) {
      query = query.where(
        'endDate',
        isGreaterThan: Timestamp.fromDate(DateTime.now()),
      );
    }

    return query.snapshots().map(
          (snap) => snap.docs.map((doc) => TripPackage.fromDoc(doc)).toList(),
    );
  }



  /// ✅ Create new trip
  static Future<void> create({
    required String title,
    required String description,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int price,
    required int capacity,
    required String createdBy,
    String? imageUrl,
    String? imagePublicId, // 👈 Cloudinary public ID
    List<String>? gallery,
    String? hotelName,
    int? hotelStars,
    List<String>? meals,
    List<String>? activities,
    bool airportPickup = false,
    List<Map<String, dynamic>>? itinerary,
  }) async {
    await _col.add({
      'title': title,
      'description': description,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'capacity': capacity,
      'bookedSeats': 0,
      'bookedSeatsList': [],
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'gallery': gallery,
      'hotelName': hotelName,
      'hotelStars': hotelStars,
      'meals': meals,
      'activities': activities,
      'airportPickup': airportPickup,
      'itinerary': itinerary,
      'travellers': [],
    });
  }

  /// ✅ Update existing trip
  static Future<void> update({
    required String tripId,
    String? title,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? price,
    int? capacity,
    String? imageUrl,
    String? imagePublicId,
    List<String>? gallery,
    String? hotelName,
    int? hotelStars,
    List<String>? meals,
    List<String>? activities,
    bool? airportPickup,
    List<Map<String, dynamic>>? itinerary,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (destination != null) updates['destination'] = destination;
    if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
    if (price != null) updates['price'] = price;
    if (capacity != null) updates['capacity'] = capacity;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (imagePublicId != null) updates['imagePublicId'] = imagePublicId;
    if (gallery != null) updates['gallery'] = gallery;
    if (hotelName != null) updates['hotelName'] = hotelName;
    if (hotelStars != null) updates['hotelStars'] = hotelStars;
    if (meals != null) updates['meals'] = meals;
    if (activities != null) updates['activities'] = activities;
    if (airportPickup != null) updates['airportPickup'] = airportPickup;
    if (itinerary != null) updates['itinerary'] = itinerary;

    await _col.doc(tripId).update(updates);
  }

  /// ✅ Book trip with traveller details
  static Future<void> bookTrip({
    required String tripId,
    required List<Map<String, dynamic>> travellers, // 👈
    required String userId,
  }) async {
    final tripRef = _col.doc(tripId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(tripRef);
      if (!snapshot.exists) {
        throw Exception("Trip not found");
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final bookedSeats = (data['bookedSeats'] as num?)?.toInt() ?? 0;
      final capacity = (data['capacity'] as num?)?.toInt() ?? 0;

      if (bookedSeats + travellers.length > capacity) {
        throw Exception("Not enough seats available");
      }

      // ✅ Update trip with travellers
      txn.update(tripRef, {
        'bookedSeats': bookedSeats + travellers.length,
        'travellers': FieldValue.arrayUnion(travellers),
      });
    });

    // ✅ Create booking record
    final tripSnapshot = await tripRef.get();
    final tripData = tripSnapshot.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance.collection('bookings').add({
      'tripPackageId': tripId,
      'userId': userId,
      'travellers': travellers,
      'seats': travellers.length,
      'amount': travellers.length * (tripData['price'] ?? 0),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ Get all trips
  static Stream<QuerySnapshot<Map<String, dynamic>>> getTrips() {
    return _col.snapshots();
  }

  /// ✅ Get one trip
  static Future<DocumentSnapshot<Map<String, dynamic>>> getTrip(String id) {
    return _col.doc(id).get();
  }

  /// ✅ Delete a trip
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
