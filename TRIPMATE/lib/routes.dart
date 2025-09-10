import 'package:flutter/material.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Role-based dashboards
import 'screens/customer_home.dart';
import 'screens/agent_home.dart';
import 'screens/admin_home.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/customerHome': (_) => const CustomerHome(),
  '/agentHome': (_) => const AgentHome(),
  '/adminHome': (_) => const AdminHome(),
  // '/authpage':(_) => const AuthPage(role: Customer),),
};
