// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // ✅ import your AppUser model

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// Sign up and create user profile in Firestore
  static Future<AppUser> signUp({
    required String email,
    required String password,
    required String role, // 'customer' | 'travel_agent' | 'admin'
    String? displayName,
    Map<String, dynamic>? extraFields,
  }) async {
    final roleNormalized = role.toLowerCase();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      final profile = <String, dynamic>{
        'email': email,
        'name': displayName ?? '',
        'role': roleNormalized,
        // customers auto-approved
        'approved': roleNormalized == 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (extraFields != null) profile.addAll(extraFields);

      await _db.collection('users').doc(user.uid).set(profile);

      // fetch back to return AppUser
      final snapshot = await _db.collection('users').doc(user.uid).get();
      return AppUser.fromDoc(snapshot);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign up failed');
    }
  }

  /// Sign in, validate role, and return AppUser
  static Future<AppUser> signInWithRole(
      String email, String password, String expectedRole) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        // profile missing → still signed in but incomplete profile
        throw Exception("Profile not found for this account. Please complete signup.");
      }

      final data = doc.data()!;
      final role = (data['role'] as String? ?? 'customer').toLowerCase();
      final approved = (data['approved'] as bool?) ?? (role == 'customer');

      if (role != expectedRole.toLowerCase()) {
        await _auth.signOut();
        throw Exception(
          'This account is registered as "$role". Please select that role to login.',
        );
      }

      if (!approved) {
        // You can choose to block login here if needed
        throw Exception("Your account is pending approval.");
      }

      return AppUser.fromDoc(doc);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign in failed');
    }
  }

  static Future<void> signOut() => _auth.signOut();

  /// Get AppUser profile by UID
  static Future<AppUser?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Stream current logged-in AppUser
  static Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.exists ? AppUser.fromDoc(doc) : null;
    });
  }

  /// Get current logged-in Firebase User
  static User? get firebaseUser => _auth.currentUser;
}
