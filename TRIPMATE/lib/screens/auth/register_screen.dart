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
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController passCtrl = TextEditingController();
  String role = "customer";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomInput(controller: emailCtrl, hintText: "Enter Email"),
            const SizedBox(height: 10),
            CustomInput(controller: passCtrl, hintText: "Enter Password", obscureText: true),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: "customer", child: Text("Customer")),
                DropdownMenuItem(value: "agent", child: Text("Agent")),
                DropdownMenuItem(value: "admin", child: Text("Admin")),
              ],
              onChanged: (val) => setState(() => role = val!),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Register",
              onPressed: () async {
                await AuthService().register(emailCtrl.text, passCtrl.text, role);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
