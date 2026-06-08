import 'dart:ui';
import 'package:flutter/material.dart';
import '../Theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radiusCard,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: (tint ?? Colors.white).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 22, offset: Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
