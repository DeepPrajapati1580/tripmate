
import 'package:flutter/material.dart';
import 'auth_page.dart';
import '../../theme.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _openAuth(BuildContext ctx, String role) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => AuthPage(role: role)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          child: Column(
            children: [

              Image.asset('assets/images/TripMate_Logo.png', height: 86),
              const SizedBox(height: 12),
              Text('TripMate', style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('Your travel companion', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    _roleCard(context, 'Customer', Icons.person, AppColors.primary),
                    _roleCard(context, 'Travel Agent', Icons.card_travel, AppColors.accent),
                    _roleCard(context, 'Admin', Icons.admin_panel_settings, AppColors.dark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(BuildContext context, String label, IconData icon, Color color) {
    final muted = AppColors.muted;
    return GestureDetector(
      onTap: () => _openAuth(context, label.toLowerCase().replaceAll(' ', '_')),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  label == 'Customer' ? 'Explore & book trips' : label == 'Travel Agent' ? 'Manage your listings' : 'Admin portal',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ]),
              const Spacer(),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
