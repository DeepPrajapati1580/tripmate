import 'package:cloud_firestore/cloud_firestore.dart';

class TripPackage {
  final String id;
  final String title;
  final String description;
  final String source; // starting city
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int price; // store in INR as integer
  final int capacity;
  final int bookedSeats; // total count
  final List<int> bookedSeatsList; // ✅ seat numbers
  final String createdBy; // uid of agent
  final DateTime createdAt; // server time when created
  final String? imageUrl; // main trip image
  final String? imagePublicId; // Cloudinary public ID
  final List<String> gallery; // trip gallery images

  // Hotel info
  final String? hotelName;
  final String? hotelDescription; // added
  final int? hotelStars;
  final String? hotelMainImage; // main hotel image
  final List<String> hotelGallery; // multiple hotel images

  final List<String> meals;
  final List<String> activities;
  final bool airportPickup;
  final List<Map<String, dynamic>> itinerary;

  // ✅ travellers
  final List<Map<String, dynamic>> travellers;

  TripPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
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
    this.gallery = const [],
    this.hotelName,
    this.hotelDescription,
    this.hotelStars,
    this.hotelMainImage,
    this.hotelGallery = const [],
    this.meals = const [],
    this.activities = const [],
    this.airportPickup = false,
    this.itinerary = const [],
    required this.travellers,
  });

  /// Create TripPackage from Firestore Document
  factory TripPackage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    return TripPackage(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      source: d['source'] ?? '',
      destination: d['destination'] ?? '',
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (d['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: (d['price'] as num?)?.toInt() ?? 0,
      capacity: (d['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: (d['bookedSeats'] as num?)?.toInt() ?? 0,
      bookedSeatsList: (d['bookedSeatsList'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
          [],
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: d['imageUrl'],
      imagePublicId: d['imagePublicId'],
      gallery: List<String>.from(d['gallery'] ?? const []),
      hotelName: d['hotelName'],
      hotelDescription: d['hotelDescription'],
      hotelStars: (d['hotelStars'] as num?)?.toInt(),
      hotelMainImage: d['hotelMainImage'],
      hotelGallery: List<String>.from(d['hotelGallery'] ?? const []),
      meals: List<String>.from(d['meals'] ?? const []),
      activities: List<String>.from(d['activities'] ?? const []),
      airportPickup: d['airportPickup'] ?? false,
      itinerary: (d['itinerary'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ??
          [],
      travellers: (d['travellers'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ??
          [],
    );
  }

  /// Convert TripPackage to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'source': source,
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
      'hotelDescription': hotelDescription,
      'hotelStars': hotelStars,
      'hotelMainImage': hotelMainImage,
      'hotelGallery': hotelGallery,
      'meals': meals,
      'activities': activities,
      'airportPickup': airportPickup,
      'itinerary': itinerary,
      'travellers': travellers,
    };
  }
}
