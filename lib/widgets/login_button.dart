import 'package:flutter/material.dart';
import 'package:forking/utils/haptic_feedback.dart';

class LoginButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const LoginButton({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: icon,
        label: Text(text, style: TextStyle(color: textColor, fontSize: 16, letterSpacing: -0.1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: () {
          HapticUtils.triggerSelection();
          onPressed?.call();
        },
      ),
    );
  }
}