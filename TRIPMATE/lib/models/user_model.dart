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

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      name: data['name'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static AppUser fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      name: data['name'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
