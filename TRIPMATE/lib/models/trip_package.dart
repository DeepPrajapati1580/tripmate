import 'package:cloud_firestore/cloud_firestore.dart';

class TripPackage {
  final String id;
  final String title;
  final String description;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int price; // store in INR as integer
  final int capacity;
  final int bookedSeats; // total count
  final List<int> bookedSeatsList; // ✅ seat numbers (keep for future use)
  final String createdBy; // uid of agent
  final DateTime createdAt; // server time when created
  final String? imageUrl; // main image
  final String? imagePublicId; // ✅ Cloudinary public ID for deletion/update
  final List<String>? gallery; // ✅ multiple images (view gallery)

  // Hotel & extras
  final String? hotelName; // e.g. Heritage Village Resort & Spa
  final int? hotelStars; // e.g. 5
  final List<String>? meals; // e.g. ["Breakfast", "Lunch"]
  final List<String>? activities; // e.g. ["Boat Party", "Water Sports"]
  final bool airportPickup; // pickup/drop availability
  final List<Map<String, dynamic>>? itinerary;
  // Each day has: { "day": 1, "date": "...", "title": "...", "meals": [...], "activities": [...] }

  // ✅ New field: travellers
  final List<Map<String, dynamic>> travellers;

  TripPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.capacity,
    required this.bookedSeats,
    required this.bookedSeatsList,
    required this.createdBy,
    required this.createdAt,
    this.imageUrl,
    this.imagePublicId,
    this.gallery,
    this.hotelName,
    this.hotelStars,
    this.meals,
    this.activities,
    this.airportPickup = false,
    this.itinerary,
    required this.travellers,
  });

  factory TripPackage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TripPackage(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      destination: d['destination'] ?? '',
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: (d['endDate'] as Timestamp).toDate(),
      price: (d['price'] as num?)?.toInt() ?? 0,
      capacity: (d['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: (d['bookedSeats'] as num?)?.toInt() ?? 0,
      bookedSeatsList: (d['bookedSeatsList'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
          [],
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: d['imageUrl'],
      imagePublicId: d['imagePublicId'],
      gallery: (d['gallery'] as List?)?.map((e) => e.toString()).toList(),
      hotelName: d['hotelName'],
      hotelStars: (d['hotelStars'] as num?)?.toInt(),
      meals: (d['meals'] as List?)?.map((e) => e.toString()).toList(),
      activities:
      (d['activities'] as List?)?.map((e) => e.toString()).toList(),
      airportPickup: d['airportPickup'] ?? false,
      itinerary: (d['itinerary'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      travellers: (d['travellers'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'capacity': capacity,
      'bookedSeats': bookedSeats,
      'bookedSeatsList': bookedSeatsList,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'gallery': gallery,
      'hotelName': hotelName,
      'hotelStars': hotelStars,
      'meals': meals,
      'activities': activities,
      'airportPickup': airportPickup,
      'itinerary': itinerary,
      'travellers': travellers,
    };
  }
}
