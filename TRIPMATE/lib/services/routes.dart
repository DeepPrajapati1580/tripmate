import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/agent/agent_home.dart';
import 'screens/admin/admin_home.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/customerHome': (_) => const CustomerHome(),
  '/agentHome': (_) => const AgentHome(),
  '/adminHome': (_) => const AdminHome(),
};
