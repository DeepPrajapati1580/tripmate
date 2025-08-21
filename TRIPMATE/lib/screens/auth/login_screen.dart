import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomInput(controller: emailCtrl, hintText: "Enter Email"),
            const SizedBox(height: 10),
            CustomInput(controller: passCtrl, hintText: "Enter Password", obscureText: true),
            const SizedBox(height: 20),
            CustomButton(
              text: "Login",
              onPressed: () async {
                final user = await AuthService().login(emailCtrl.text, passCtrl.text);
                if (user != null) {
                  context.read<UserProvider>().setUser(user);
                  if (user.role == "customer") {
                    Navigator.pushReplacementNamed(context, '/customerHome');
                  } else if (user.role == "agent") {
                    Navigator.pushReplacementNamed(context, '/agentHome');
                  } else {
                    Navigator.pushReplacementNamed(context, '/adminHome');
                  }
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Don't have an account? Register"),
            )
          ],
        ),
      ),
    );
  }
}
