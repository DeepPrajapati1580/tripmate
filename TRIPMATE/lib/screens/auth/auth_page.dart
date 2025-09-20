// lib/screens/auth_page.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../../models/user_model.dart'; // AppUser
import '../../main.dart'; // for AuthWrapper

class AuthPage extends StatefulWidget {
  final String role;
  final bool isSignupFlow;
  const AuthPage({super.key, required this.role, this.isSignupFlow = false});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _agency = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    isLogin = !widget.isSignupFlow;
  }

  void _show(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _agency.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (isLogin) {
        // Login
        final AppUser? user = await AuthService.signInWithRole(
          _email.text.trim(),
          _password.text.trim(),
          widget.role,
        );

        if (user == null) {
          if (mounted) _show("Login failed. Please check credentials or role.");
          return;
        }

        if (mounted) {
          _show('Welcome, ${user.name ?? user.email}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
        }
      } else {
        // Signup
        final extra = widget.role == 'travel_agent'
            ? {'agencyName': _agency.text.trim()}
            : null;

        await AuthService.signUp(
          email: _email.text.trim(),
          password: _password.text.trim(),
          role: widget.role,
          displayName: _name.text.trim(),
          extraFields: extra,
        );

        if (mounted) {
          _show(widget.role == 'customer'
              ? 'Signup successful — you are logged in'
              : 'Signup successful — pending admin approval');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
        }
      }
    } catch (e) {
      if (mounted) _show(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.role.replaceAll('_', ' ').toUpperCase();
    return Scaffold(
      appBar: AppBar(title: Text('$roleLabel — ${isLogin ? "Login" : "Sign Up"}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset('assets/images/TripMate_Logo.png', height: 82),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!isLogin)
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: (v) =>
                          v != null && v.trim().isNotEmpty ? null : 'Full name is required',
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v != null && v.contains('@')
                            ? null
                            : 'Enter a valid email',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => v != null && v.length >= 6
                            ? null
                            : 'Password must be at least 6 characters',
                      ),
                      if (!isLogin && widget.role == 'travel_agent') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _agency,
                          decoration: const InputDecoration(labelText: 'Agency Name'),
                          validator: (v) =>
                          v != null && v.trim().isNotEmpty
                              ? null
                              : 'Agency name is required',
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isLogin ? 'Login' : 'Create account'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(isLogin
                            ? 'Create new account'
                            : 'Already have an account? Login'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/reset-password');
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
