import 'package:flutter/material.dart';

class CyberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;

  const CyberTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace'),
      cursorColor: const Color(0xFF00FF41),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF484F58), fontSize: 11, letterSpacing: 2),
        hintStyle: const TextStyle(color: Color(0xFF2A2F3A), fontFamily: 'monospace'),
        prefixIcon: Icon(icon, color: const Color(0xFF484F58), size: 18),
        filled: true,
        fillColor: const Color(0xFF060A12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFF1A2030)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFF1A2030)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFF00FF41), width: 1),
        ),
      ),
    );
  }
}
