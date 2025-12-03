import 'package:flutter/material.dart';

class SentiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SentiCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we are in Dark Mode
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Light Mode Colors
    const Color lightCard = Color(0xFFF7F6F1);
    const Color lightShadow = Color(0xFFEBEAE4);

    // Dark Mode Colors
    const Color darkCard = Color(0xFF1E1E1E); // Dark Grey
    const Color darkShadow = Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? darkCard : lightCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? darkShadow : lightShadow, 
              blurRadius: 0, 
              offset: const Offset(0, 6), 
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}