// lib/screens/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address')));
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email — check inbox and spam.')),
      );
      // Optionally navigate back to login after success:
      // Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Try again later.';
          break;
        default:
          message = e.message ?? 'Failed to send reset email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong. Try again.')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password'),
      actions:[
        IconButton(
          icon: const Icon(Icons.login),
          tooltip:'Go to Login',
          onPressed: () async{
            // await FirebaseAuth.instance.signOut();
            
              Navigator.of(context).pushReplacementNamed('/login');
            
          },
        ),
      ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter the email for your TripMate account. We will send a link to reset your password.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendResetEmail,
                child: _isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send reset email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
