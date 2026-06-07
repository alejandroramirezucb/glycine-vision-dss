import 'package:flutter/material.dart';

class AppTheme {
  static const bgPage = Color(0xFFEBF0F3);
  static const bgCard = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDE6EA);
  static const accent = Color(0xFF1A7F89);
  static const accentDark = Color(0xFF0F6B73);
  static const accentLight = Color(0xFF2A9D97);
  static const textPrimary = Color(0xFF0A3136);
  static const textMuted = Color(0xFF4E6A70);
  static const urgentCrit = Color(0xFFC0392B);
  static const urgentHigh = Color(0xFFE67E22);
  static const urgentMed = Color(0xFFF39C12);

  static const double radiusCard = 28.0;
  static const double radiusBtn = 24.0;
  static const double radiusChip = 14.0;
  static const double radiusImg = 22.0;
  static const double radiusBadge = 6.0;
  static const double imgHeight = 256.0;
  static const double btnHeight = 46.0;
  static const double phoneWidth = 390.0;

  static const Duration animFast = Duration(milliseconds: 120);
  static const Duration animNormal = Duration(milliseconds: 280);
  static const Duration animSlow = Duration(milliseconds: 450);
  static const Duration staggerDelay = Duration(milliseconds: 80);
  static const Curve easeOutCurve = Curves.easeOut;
  static const Curve springCurve = Curves.elasticOut;

  static const Color sevMinima = Color(0xFF2E9E7A);
  static const Color sevLeve = Color(0xFFC9A227);
  static const Color sevModerada = Color(0xFFE08A1E);
  static const Color sevSevera = Color(0xFFCF5A2A);
  static const Color sevCritica = Color(0xFFB23A2E);

  static const Map<String, Color> _severityLevelColors = {
    'critica':  sevCritica,
    'severa':   sevSevera,
    'moderada': sevModerada,
    'leve':     sevLeve,
    'minima':   sevMinima,
  };

  static Color severityLevelColor(String level) =>
      _severityLevelColors[level.toLowerCase()] ?? sevMinima;

  static Color severityPctColor(double pct) {
    if (pct < 5) return sevMinima;
    if (pct < 15) return sevLeve;
    if (pct < 35) return sevModerada;
    if (pct < 60) return sevSevera;
    return sevCritica;
  }

  static BoxDecoration cardDecoration() => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      );

  static ButtonStyle elevatedButtonStyle(Color bgColor) =>
      ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: bgColor.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusBtn)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(double.infinity, btnHeight),
      );

  static ButtonStyle headerButtonStyle(Color bgColor) =>
      ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusBtn)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 34),
      );

  static ThemeData themeData() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgPage,
        appBarTheme: const AppBarTheme(
          backgroundColor: bgCard,
          surfaceTintColor: Colors.transparent,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(false),
          thickness: WidgetStateProperty.all(5),
          radius: const Radius.circular(8),
          crossAxisMargin: 4,
          thumbColor: WidgetStateProperty.all(
              Colors.grey.withValues(alpha: 0.35)),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        ),
      );
}
