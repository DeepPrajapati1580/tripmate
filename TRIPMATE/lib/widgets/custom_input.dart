// lib/widgets/custom_input.dart
import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? label;
  final bool obscureText;

  const CustomInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.label,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label?.isNotEmpty == true ? label : null,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
