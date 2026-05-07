import 'package:flutter/material.dart';

class GlitchText extends StatelessWidget {
  final String text;
  final double fontSize;
  const GlitchText(this.text, {super.key, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00FF41),
            letterSpacing: 3,
          ),
        ),
        Positioned(
          left: 2,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              // ignore: deprecated_member_use
              color: const Color(0xFF00FFFF).withOpacity(0.15),
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}
