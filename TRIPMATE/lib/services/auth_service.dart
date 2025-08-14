// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // signUp (no change needed, but ensure role stored lowercase)
  static Future<void> signUp({
    required String email,
    required String password,
    required String role, // 'customer' | 'travel_agent' | 'admin'
    String? displayName,
    Map<String, dynamic>? extraFields,
  }) async {
    final roleNormalized = role.toLowerCase();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user!;
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      final profile = <String, dynamic>{
        'email': email,
        'displayName': displayName ?? '',
        'role': roleNormalized,
        // customers auto-approved; change below if you want other behavior
        'approved': roleNormalized == 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (extraFields != null) profile.addAll(extraFields);

      await _db.collection('users').doc(user.uid).set(profile);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign up failed');
    }
  }

  /// Sign in and return profile info. DOES NOT sign out user if not approved.
  /// Throws if role mismatch.
  static Future<Map<String, dynamic>> signInWithRole(String email, String password, String expectedRole) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        // profile missing — keep user signed in so they can finish signup, but inform caller
        return {'role': null, 'approved': false};
      }
      final data = doc.data()!;
      final role = (data['role'] as String? ?? 'customer').toLowerCase();
      final approved = (data['approved'] as bool?) ?? (role == 'customer');

      if (role != expectedRole.toLowerCase()) {
        // wrong role selected — sign out and throw so UI shows error
        await _auth.signOut();
        throw Exception('This account is registered as "$role". Please select that role to login.');
      }

      // success: return role & approval (do not sign out if not approved)
      return {'role': role, 'approved': approved};
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign in failed');
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
