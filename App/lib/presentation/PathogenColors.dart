import 'package:flutter/material.dart';

Color pathogenColor(String pathogenClass) => switch (pathogenClass.toLowerCase()) {
      'roya' => const Color(0xFFFF6F00),
      'fungicas' => const Color(0xFF1B5E20),
      'bacterianas' => const Color(0xFF0D47A1),
      'virales' => const Color(0xFF4A148C),
      'plagas_insectos' => const Color(0xFFB71C1C),
      _ => const Color(0xFFBF360C),
    };

Color urgencyColor(String urgencia) => switch (urgencia.toLowerCase()) {
      'critica' => const Color(0xFFC0392B),
      'alta' => const Color(0xFFE67E22),
      'media' => const Color(0xFFF39C12),
      'baja' => const Color(0xFF388E3C),
      _ => const Color(0xFF607D8B),
    };
