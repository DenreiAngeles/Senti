import 'package:flutter/material.dart';

class Pressable3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap; // Nullable to support "disabled" state
  final Color color;
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const Pressable3DButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = Colors.white,
    this.height = 40,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  State<Pressable3DButton> createState() => _Pressable3DButtonState();
}

class _Pressable3DButtonState extends State<Pressable3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    bool isDisabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        height: widget.height,
        width: widget.width,
        // Move down by 4px when pressed (or 0 if disabled/unpressed)
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(30),
          // Only show shadow if enabled and NOT pressed
          boxShadow: (_isPressed || isDisabled)
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4), // The "3D" depth
                    blurRadius: 1,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}