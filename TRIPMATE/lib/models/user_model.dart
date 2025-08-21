import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String role; // customer / agent / admin
  final String? name;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    required this.createdAt,
  });

  /// Copy user with modified fields
  AppUser copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to JSON (alias for toMap)
  Map<String, dynamic> toJson() => toMap();

  /// Create from Firestore DocumentSnapshot
  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      name: data['name'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create from raw Map
  static AppUser fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      name: data['name'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create from JSON
  factory AppUser.fromJson(String id, Map<String, dynamic> json) {
    return AppUser.fromMap(id, json);
  }

  /// Equality by user id
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && id == other.id);

  @override
  int get hashCode => id.hashCode;

  /// Debug print
  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, role: $role, name: $name, createdAt: $createdAt)';
  }
}
