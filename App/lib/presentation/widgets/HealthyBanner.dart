import 'package:flutter/material.dart';
import '../Theme.dart';

class HealthyBanner extends StatefulWidget {
  const HealthyBanner({super.key});

  @override
  State<HealthyBanner> createState() => _HealthyBannerState();
}

class _HealthyBannerState extends State<HealthyBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), _shimmer.value)!,
              Color.lerp(const Color(0xFFC8E6C9), const Color(0xFFE8F5E9), _shimmer.value)!,
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoja sana',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'No se detectaron enfermedades. Continuar con monitoreo preventivo.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
