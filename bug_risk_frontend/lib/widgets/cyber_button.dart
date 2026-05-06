import 'package:flutter/material.dart';

class CyberButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const CyberButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF00FF41),
          side: const BorderSide(color: Color(0xFF00FF41)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Color(0xFF00FF41), strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00FF41),
                  letterSpacing: 3,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
