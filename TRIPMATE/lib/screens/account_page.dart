// lib/screens/account_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_home.dart';
import 'customer/my_bookings_page.dart';
import './agent_home.dart';
import './admin_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<String> _getUserRole(User user) async {
    // Example: fetch role from Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data()?['role'] ?? 'customer';
    }
    return 'customer'; // default
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("No user logged in."),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _getUserRole(user),
      builder: (context, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = roleSnap.data ?? 'customer';

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              // ---------- Header ----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.displayName != null && user.displayName!.isNotEmpty
                            ? user.displayName![0].toUpperCase()
                            : "A",
                        style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 40,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName ?? "Anonymous",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? "No email",
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------- Functional Buttons ----------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      if (role == 'customer') ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading:
                            const Icon(Icons.card_travel, color: Colors.teal),
                            title: const Text("Available Trips"),
                            trailing:
                            const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerHome(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading:
                            const Icon(Icons.book_online, color: Colors.teal),
                            title: const Text("My Bookings"),
                            trailing:
                            const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MyBookingsPage(userId: user.uid),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (role == 'agent') ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.list, color: Colors.teal),
                            title: const Text("My Trips & Bookings"),
                            trailing:
                            const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgentHome(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (role == 'admin') ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.admin_panel_settings,
                                color: Colors.teal),
                            title: const Text("Admin Panel"),
                            trailing:
                            const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminHome(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Logout button (all roles)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
