// TRIPMATE/lib/screens/admin_home.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  Future<void> _approve(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'approved': true});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ Agent approved')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Approve failed: $e')));
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate();
    return DateFormat.yMMMd().add_jm().format(dt);
  }

  Widget _userTile(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc, {
        bool showApprove = false,
      }) {
    final data = doc.data();
    final name = (data['name'] ?? data['displayName'])?.toString() ?? '';
    final email = (data['email'] ?? '').toString();
    final lastLoginTs = data['lastLogin'] as Timestamp?;
    final approved = (data['approved'] as bool?) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Icon(
            showApprove ? Icons.verified_user : Icons.person,
            color: Colors.deepPurple,
          ),
        ),
        title: Text(name.isNotEmpty ? name : email,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Last login: ${_formatTimestamp(lastLoginTs)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (showApprove)
              Text('Status: ${approved ? 'Approved ✅' : 'Pending ⏳'}',
                  style: TextStyle(
                      fontSize: 12,
                      color: approved ? Colors.green : Colors.orange)),
          ],
        ),
        trailing: showApprove && !approved
            ? ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () => _approve(context, doc.id),
          child: const Text('Approve'),
        )
            : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          )
        ],
      ),
    );
  }

  Widget _statCard(
      {required String label,
        required String value,
        required Color color,
        required IconData icon}) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'customer');
    final agentsRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'travel_agent');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ Stats moved to top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: customersRef.snapshots(),
                    builder: (context, snapshot) {
                      final count =
                      snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _statCard(
                          label: "Customers",
                          value: count.toString(),
                          color: Colors.teal,
                          icon: Icons.people);
                    },
                  ),
                  const SizedBox(width: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: agentsRef.snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final pending = docs
                          .where(
                              (d) => (d.data()['approved'] as bool?) != true)
                          .length;
                      return _statCard(
                          label: "Pending",
                          value: pending.toString(),
                          color: Colors.orange,
                          icon: Icons.hourglass_empty);
                    },
                  ),
                  const SizedBox(width: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: agentsRef.snapshots(),
                    builder: (context, snapshot) {
                      final count =
                      snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _statCard(
                          label: "Agents",
                          value: count.toString(),
                          color: Colors.green,
                          icon: Icons.work);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Customers
              _sectionCard(
                title: "Customers",
                icon: Icons.people,
                color: Colors.teal,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: customersRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text('No customers found');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (c, i) =>
                          _userTile(context, docs[i], showApprove: false),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Travel Agents
              _sectionCard(
                title: "Travel Agents",
                icon: Icons.work,
                color: Colors.teal,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: agentsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text('No agents found');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (c, i) =>
                          _userTile(context, docs[i], showApprove: true),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}