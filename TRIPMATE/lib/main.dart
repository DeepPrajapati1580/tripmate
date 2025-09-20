import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/auth/role_selection_page.dart';
import 'screens/auth/pending_approval_page.dart';
import 'screens/customer_home.dart';
import 'screens/agent_home.dart';
import 'screens/admin_home.dart';
import 'screens/auth/auth_page.dart';
import 'screens/auth/reset_password_page.dart';
import 'screens/auth/login_screen.dart';

import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';

import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(cloudName: 'dbdhnrhur');

  runApp(const TripMateApp());
}

class TripMateApp extends StatelessWidget {
  const TripMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripMate',
      theme: buildAppTheme(),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/reset-password': (context) => const ResetPasswordPage(),
        '/login': (context) => const LoginScreen(),
        '/customerHome': (_) => const CustomerHome(),
        '/agentHome': (_) => const AgentHome(),
        '/adminHome': (_) => const AdminHome(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) {
          
          return const RoleSelectionPage();
        }

        
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!docSnap.hasData || !docSnap.data!.exists) {
              
              return AuthPage(role: 'customer', isSignupFlow: true);
            }

            final data = docSnap.data!.data()!;
            final role = (data['role'] as String? ?? 'customer').toLowerCase();
            final approved = (data['approved'] as bool?) ?? false;

           
            if ((role == 'travel_agent' || role == 'admin') && !approved) {
              return const PendingApprovalPage();
            }

           
            switch (role) {
              case 'admin':
                return const AdminHome();
              case 'travel_agent':
                return const AgentHome();
              default:
                return const CustomerHome();
            }
          },
        );
      },
    );
  }
}
