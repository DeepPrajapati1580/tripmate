import 'package:cloud_firestore/cloud_firestore.dart';

class TripPackage {
  final String id;
  final String title;
  final String description;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int price;
  final int capacity;
  final int bookedSeats;
  final String createdBy;            // agent uid
  final DateTime? createdAt;         // may be null if very fresh write
  final String? imageUrl;

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
    required this.createdBy,
    this.createdAt,
    this.imageUrl,
  });

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
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    };
  }

  static TripPackage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final tsStart = data['startDate'];
    final tsEnd = data['endDate'];
    final tsCreated = data['createdAt'];

    final priceFromEither =
        (data['price'] as num?)?.toInt() ??
        (data['pricePerSeat'] as num?)?.toInt() ??
        0;

    return TripPackage(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      destination: (data['destination'] ?? '').toString(),
      startDate: tsStart is Timestamp ? tsStart.toDate() : DateTime.now(),
      endDate: tsEnd is Timestamp ? tsEnd.toDate() : DateTime.now(),
      price: priceFromEither,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: (data['bookedSeats'] as num?)?.toInt() ?? 0,
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: tsCreated is Timestamp ? tsCreated.toDate() : null,
      imageUrl: (data['imageUrl'] as String?),
    );
  }

  bool get hasSeatsAvailable => bookedSeats < capacity;
  int get remainingSeats => capacity - bookedSeats;
}
