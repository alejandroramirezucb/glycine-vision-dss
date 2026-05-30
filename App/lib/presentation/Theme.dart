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

  static const Map<String, Color> _severityLevelColors = {
    'critica':  Color(0xFFB71C1C),
    'severa':   Color(0xFFE53935),
    'moderada': Color(0xFFFB8C00),
    'leve':     Color(0xFFFDD835),
  };
  static const Color _severityDefault = Color(0xFF43A047);

  static Color severityLevelColor(String level) =>
      _severityLevelColors[level.toLowerCase()] ?? _severityDefault;

  static Color severityPctColor(double pct) {
    if (pct < 5) return Colors.green;
    if (pct < 15) return Colors.lightGreen;
    if (pct < 35) return const Color(0xFFFB8C00);
    if (pct < 60) return const Color(0xFFE53935);
    return const Color(0xFFB71C1C);
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
