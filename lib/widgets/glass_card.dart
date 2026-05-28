import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const GlassCard({
    Key? key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.08,
    this.color,
    this.borderRadius,
    this.padding,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark ? Colors.black : (color ?? Colors.white);
    final fallbackOpacity = isDark ? 0.35 : opacity;
    final fallbackBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: fallbackBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fallbackColor.withOpacity(fallbackOpacity),
            borderRadius: fallbackBorderRadius,
            border: border ?? Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
