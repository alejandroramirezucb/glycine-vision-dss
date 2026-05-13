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
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Glycine Vision',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentDark,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canGoBack)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    style: AppTheme.headerButtonStyle(AppTheme.accent),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: onHome,
                icon: const Icon(Icons.home),
                label: const Text('Inicio'),
                style: AppTheme.headerButtonStyle(AppTheme.accentLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
