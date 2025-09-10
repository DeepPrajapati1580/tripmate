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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent approved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
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

    return ListTile(
      title: Text(name.isNotEmpty ? name : email),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(email),
          const SizedBox(height: 4),
          Text('Last login: ${_formatTimestamp(lastLoginTs)}'),
          if (showApprove) Text('Status: ${approved ? 'Approved' : 'Pending'}'),
        ],
      ),
      trailing: showApprove && !approved
          ? ElevatedButton(
              onPressed: () => _approve(context, doc.id),
              child: const Text('Approve'),
            )
          : null,
      isThreeLine: true,
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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top row: two cards side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customers card
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customers',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>>(
                              stream: customersRef.snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return const Text('No customers found');
                                }
                                return SizedBox(
                                  height: 260,
                                  child: ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (c, i) => _userTile(
                                      context,
                                      docs[i],
                                      showApprove: false,
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Travel Agents card
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Travel Agents',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>>(
                              stream: agentsRef.snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return const Text('No agents found');
                                }
                                return SizedBox(
                                  height: 260,
                                  child: ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (c, i) => _userTile(
                                      context,
                                      docs[i],
                                      showApprove: true,
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Stats Row (counts)
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: customersRef.snapshots(),
                      builder: (context, snapshot) {
                        final count =
                            snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Card(
                          child: ListTile(
                            title: const Text('Total customers'),
                            trailing: Text(count.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: agentsRef.snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        final pending = docs
                            .where((d) =>
                                (d.data()['approved'] as bool?) != true)
                            .length;
                        return Card(
                          child: ListTile(
                            title: const Text('Agents (pending)'),
                            trailing: Text(pending.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: agentsRef.snapshots(),
                      builder: (context, snapshot) {
                        final count =
                            snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Card(
                          child: ListTile(
                            title: const Text('Total agents'),
                            trailing: Text(count.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
