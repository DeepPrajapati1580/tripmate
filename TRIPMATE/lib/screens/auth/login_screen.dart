
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:tripmate/models/user_model.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'customer';
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final AppUser? user = await AuthService.signInWithRole(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      _selectedRole,
    );

    if (!mounted) return;

    if (user == null) {
      setState(() => _error = "Login failed. Please check credentials.");
      return;
    }

    // ✅ Navigate based on role
    if (user.role == 'customer') {
      Navigator.pushReplacementNamed(context, '/customerHome');
    } else if (user.role == 'travel_agent') {
      Navigator.pushReplacementNamed(context, '/agentDashboard');
    } else if (user.role == 'admin') {
      Navigator.pushReplacementNamed(context, '/adminPanel');
    }
  } catch (e) {
    setState(() => _error = e.toString());
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter password" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: "Role"),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text("Customer")),
                  DropdownMenuItem(
                      value: 'travel_agent', child: Text("Travel Agent")),
                  DropdownMenuItem(value: 'admin', child: Text("Admin")),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
