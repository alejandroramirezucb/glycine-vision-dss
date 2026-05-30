import 'package:flutter/material.dart';
import '../Theme.dart';

class AppHeader extends StatelessWidget {
  final bool canGoBack;
  final VoidCallback onHome;
  final VoidCallback onBack;

  const AppHeader({
    super.key,
    required this.canGoBack,
    required this.onHome,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: AppTheme.bgCard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.eco, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Glycine Vision',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentDark,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (canGoBack) ...[
                _NavButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  label: 'Volver',
                  onTap: onBack,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 8),
              ],
              _NavButton(
                icon: Icons.home_rounded,
                label: 'Inicio',
                onTap: onHome,
                color: AppTheme.accentLight,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.border),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
