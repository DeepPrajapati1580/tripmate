import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/role_selection_page.dart';
import 'screens/pending_approval_page.dart';
import 'screens/customer_home.dart';
import 'screens/agent_home.dart';
import 'screens/admin_home.dart';
import 'screens/auth_page.dart';

import 'theme.dart';
import 'screens/reset_password_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TripMateApp());
}

class TripMateApp extends StatelessWidget {
  const TripMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    title:'TripMate',
    theme:buildAppTheme(),
    home : const AuthWrapper(),
    debugShowCheckedModeBanner: false,
    routes: {
    '/reset-password': (context) => const ResetPasswordPage(),
  },
      
    );
  }
}

// in lib/main.dart — replace your previous AuthWrapper with this:

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnap.data;
        if (user == null) {
          return const RoleSelectionPage();
        }

        // Listen to the user's Firestore document in real-time
        final userDocStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // If no profile yet, send them to signup flow to complete profile
            if (!docSnap.hasData || !docSnap.data!.exists) {
              // Let them remain signed in and create profile (AuthPage can handle isSignupFlow)
              return AuthPage(role: 'customer', isSignupFlow: true);
            }

            final data = docSnap.data!.data()!;
            final role = (data['role'] as String? ?? 'customer').toLowerCase();
            final approved = (data['approved'] as bool?) ?? (role == 'customer') || (role == 'admin') || (role == 'travel_agent');

            if (!approved) {
              // user is signed in but awaiting approval
              return const PendingApprovalPage();
            }

            // route by role
            if (role == 'admin') return const AdminHome();
            if (role == 'travel_agent') return const AgentHome();
            return const CustomerHome();
          },
        );
      },
    );
  }
}
