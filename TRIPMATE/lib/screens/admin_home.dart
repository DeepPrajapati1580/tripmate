// TRIPMATE/lib/screens/admin_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final customersRef = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'customer');
  final agentsRef = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'travel_agent');

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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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

  // Sticky header
  SliverPersistentHeader _buildHeader(String title) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverHeaderDelegate(
        minHeight: 50,
        maxHeight: 50,
        child: Container(
          color: Colors.grey.shade200,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Build a sliver list from stream
  Widget _buildUserSliverList(Stream<QuerySnapshot<Map<String, dynamic>>> stream,
      {bool showApprove = false}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()));
        }
        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No users found'),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) =>
                _userTile(context, docs[index], showApprove: showApprove),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return CustomScrollView(
          slivers: [
            _buildHeader("Customers"),
            _buildUserSliverList(customersRef.snapshots(), showApprove: false),
            _buildHeader("Travel Agents"),
            _buildUserSliverList(agentsRef.snapshots(), showApprove: true),
          ],
        );
      case 1:
        final pendingAgentsRef = agentsRef.where('approved', isEqualTo: false);
        return CustomScrollView(
          slivers: [
            _buildHeader("Pending Travel Agents"),
            _buildUserSliverList(pendingAgentsRef.snapshots(), showApprove: true),
          ],
        );
      case 2:
        return Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            onPressed: () => _logout(context),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "All Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.hourglass_empty), label: "Pending"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),
    );
  }
}

// Delegate for sticky header
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
