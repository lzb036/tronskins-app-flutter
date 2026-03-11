import 'package:flutter/material.dart';

class CustomAnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Duration duration;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color normalColor;
  final Color pressedColor;
  final double normalScale;
  final double pressedScale;
  final Color normalIconColor;
  final Color pressedIconColor;

  const CustomAnimatedIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.duration = const Duration(milliseconds: 100),
    this.padding = const EdgeInsets.all(5),
    this.borderRadius = 20,
    this.normalColor = Colors.transparent,
    this.pressedColor = Colors.white,
    this.normalScale = 1.0,
    this.pressedScale = 0.9,
    this.normalIconColor = Colors.white,
    this.pressedIconColor = Colors.white,
  });

  @override
  State<CustomAnimatedIconButton> createState() =>
      _CustomAnimatedIconButtonState();
}

class _CustomAnimatedIconButtonState extends State<CustomAnimatedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: widget.duration,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.pressedColor.withValues(alpha: 0.2)
              : widget.normalColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Transform.scale(
          scale: _isPressed ? widget.pressedScale : widget.normalScale,
          child: Icon(
            widget.icon,
            color: _isPressed
                ? widget.pressedIconColor.withValues(alpha: 0.8)
                : widget.normalIconColor,
          ),
        ),
      ),
    );
  }
}
