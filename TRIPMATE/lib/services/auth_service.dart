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

static Future<AppUser?> signInWithRole(String email, String password, String role) async {
  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;

    if (user != null) {
      // 🔹 get user document reference
      final docRef = _db.collection('users').doc(user.uid);

      // 🔹 update last login
      await docRef.update({'lastLogin': FieldValue.serverTimestamp()});

      // 🔹 fetch updated user document
      final updatedDoc = await docRef.get();

      final appUser = AppUser.fromDoc(updatedDoc);
      if (appUser.role == role) {
        return appUser;
      } else {
        await _auth.signOut();
        return null;
      }
    }
  } catch (e) {
    print("Error in signInWithRole: $e");
    rethrow;
  }
  return null;
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
