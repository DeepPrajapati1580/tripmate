import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String role; // customer / agent / admin
  final String? name;
  final DateTime createdAt;
  final bool approved;
  final DateTime? lastLogin;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    required this.createdAt,
    this.approved = false,
    this.lastLogin,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    DateTime? createdAt,
    bool? approved,
    DateTime? lastLogin,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      approved: approved ?? this.approved,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      name: data['name'],
      createdAt: (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      approved: (data['approved'] as bool?) ?? ((data['role'] as String?)?.toLowerCase() == 'customer'),
      lastLogin: (data['lastLogin'] is Timestamp) ? (data['lastLogin'] as Timestamp).toDate() : null,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, role: $role, name: $name, createdAt: $createdAt, approved: $approved, lastLogin: $lastLogin)';
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is AppUser && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
