import 'package:flutter/material.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController agencyCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String role = "customer"; // 'customer' | 'travel_agent' | 'admin'
  bool _loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    agencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final extra = role == 'travel_agent'
          ? {'agencyName': agencyCtrl.text.trim()}
          : null;

      await AuthService.signUp(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        role: role,
        displayName: nameCtrl.text.trim(),
        extraFields: extra,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            role == 'customer'
                ? 'Registration successful. You are now signed in.'
                : 'Registration submitted. Pending admin approval.',
          ),
        ),
      );

      // Navigate based on role immediately after signup
      if (role == "customer") {
        Navigator.pushReplacementNamed(context, '/customerHome');
      } else if (role == "travel_agent") {
        Navigator.pushReplacementNamed(context, '/agentHome');
      } else {
        Navigator.pushReplacementNamed(context, '/adminHome');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomInput(
                controller: nameCtrl,
                hintText: "Enter Full Name",
              ),
              const SizedBox(height: 10),
              CustomInput(
                controller: emailCtrl,
                hintText: "Enter Email",
              ),
              const SizedBox(height: 10),
              CustomInput(
                controller: passCtrl,
                hintText: "Enter Password",
                obscureText: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "customer",
                    child: Text("Customer"),
                  ),
                  DropdownMenuItem(
                    value: "travel_agent",
                    child: Text("Agent (Travel Agent)"),
                  ),
                  DropdownMenuItem(
                    value: "admin",
                    child: Text("Admin"),
                  ),
                ],
                onChanged: (val) => setState(() => role = val!),
              ),
              if (role == 'travel_agent') ...[
                const SizedBox(height: 10),
                CustomInput(
                  controller: agencyCtrl,
                  hintText: "Enter Agency Name (optional)",
                ),
              ],
              const SizedBox(height: 20),
              CustomButton(
                text: _loading ? "Please wait..." : "Register",
                onPressed: _loading ? null : _register,
              ),


              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
