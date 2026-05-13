import 'package:flutter/material.dart';

class AppTheme {
  static const bgPage = Color(0xFFE8EDF0);
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
  static const double imgHeight = 256.0;
  static const double btnHeight = 44.0;
  static const double phoneWidth = 390.0;

  static BoxDecoration cardDecoration() => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static ButtonStyle elevatedButtonStyle(Color bgColor) =>
      ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: bgColor.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusBtn)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(double.infinity, btnHeight),
      );

  static ButtonStyle headerButtonStyle(Color bgColor) =>
      ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusBtn)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, btnHeight),
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
