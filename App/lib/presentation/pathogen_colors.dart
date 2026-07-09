import 'package:flutter/material.dart';

Color pathogenColor(String pathogenClass) => switch (pathogenClass.toLowerCase()) {
      'roya' => const Color(0xFFFF6F00),
      'fungicas' => const Color(0xFF1B5E20),
      'bacterianas' => const Color(0xFF0D47A1),
      'virales' => const Color(0xFF6A1B9A),
      'plagas_insectos' => const Color(0xFF6D4C41),
      _ => const Color(0xFF455A64),
    };
