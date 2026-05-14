import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/ClimateData.dart';
import '../domain/DiseaseFinding.dart';
import '../domain/Protocols.dart';
import '../domain/StringNormalizer.dart';
import '../domain/Treatment.dart';
import '../domain/TreatmentPlan.dart';

class JsonTreatmentRepository implements TreatmentRepository {
  static const double _minCoveragePct = 5.0;
  static const Map<String, int> _severityRank = {
    'minima': 0,
    'leve': 1,
    'moderada': 2,
    'severa': 3,
    'critica': 4,
  };
  static const List<String> _severityOrder = [
    'minima',
    'leve',
    'moderada',
    'severa',
    'critica',
  ];
  static const Map<String, String> _labelMap = {
    'bacterial_diseases': 'bacterianas',
    'fungal_diseases': 'fungicas',
    'rust_disease': 'roya',
    'viral_diseases': 'virales',
    'insect_pests': 'plagas_insectos',
  };

  final Map<String, Map<String, dynamic>> _diseaseData;
  final List<_Incompatibility> _incompatibilities;
  final Map<String, String> _ventanas;

  JsonTreatmentRepository._(this._diseaseData, this._incompatibilities, this._ventanas);

  static Future<JsonTreatmentRepository> load() async {
    final jsonText = await rootBundle.loadString('assets/data/tratamientos.json');
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    final meta = root['_meta'] as Map<String, dynamic>? ?? {};
    final incompatibilities = _parseIncompatibilities(meta);
    final ventanas = _parseVentanas(meta);
    final diseases = <String, Map<String, dynamic>>{};
    for (final entry in root.entries) {
      if (entry.key == '_meta') continue;
      diseases[entry.key] = entry.value as Map<String, dynamic>;
    }
    return JsonTreatmentRepository._(diseases, incompatibilities, ventanas);
  }

  static List<_Incompatibility> _parseIncompatibilities(Map<String, dynamic> meta) {
    final raw = meta['incompatibilities'] as List? ?? [];
    return raw
        .map((e) => _Incompatibility.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Map<String, String> _parseVentanas(Map<String, dynamic> meta) {
    final raw = meta['ventanas_aplicacion'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, v.toString()));
  }

  @override
  TreatmentPlan buildComposite({
    required List<DiseaseFinding> findings,
    ClimateData? climate,
  }) {
    final relevant = findings.where((f) => f.coveragePct >= _minCoveragePct).toList();
    if (relevant.isEmpty) {
      return const TreatmentPlan(
        priorities: [],
        warnings: [],
        ventanaAplicacion: null,
        ajusteClimatico: null,
      );
    }

    final priorities = relevant
        .map((f) => _buildPriority(f, climate))
        .where((p) => p != null)
        .cast<TreatmentPriority>()
        .toList();

    priorities.sort((a, b) =>
        _rankSeverity(b.severityLevel).compareTo(_rankSeverity(a.severityLevel)));

    final warnings = _findWarnings(priorities);
    final ventana = _shortestVentana(priorities);
    final ajuste = climate == null ? null : _climateGuidance(climate);

    return TreatmentPlan(
      priorities: priorities,
      warnings: warnings,
      ventanaAplicacion: ventana,
      ajusteClimatico: ajuste,
    );
  }

  TreatmentPriority? _buildPriority(DiseaseFinding finding, ClimateData? climate) {
    final key = _resolveKey(finding.pathogenClass);
    final body = _diseaseData[key];
    if (body == null) return null;
    final adjustedLevel = _applyClimateModifier(finding, climate);
    final actions = _readActions(key, body, adjustedLevel);
    if (actions == null) return null;
    return TreatmentPriority(
      pathogenClass: key,
      severityLevel: adjustedLevel,
      urgencia: actions.$2,
      rationale: _rationaleFor(finding, adjustedLevel, climate),
      actions: actions.$1,
    );
  }

  String _resolveKey(String label) {
    final norm = normalizeKey(label);
    return _labelMap[norm] ?? _labelMap[label] ?? norm;
  }

  (TreatmentActions, String)? _readActions(
    String key,
    Map<String, dynamic> body,
    String severity,
  ) {
    final porSev = body['por_severidad'] as Map<String, dynamic>?;
    if (porSev == null) return null;
    final entry = porSev[severity] as Map<String, dynamic>? ??
        porSev['moderada'] as Map<String, dynamic>? ??
        porSev.values.first as Map<String, dynamic>;
    final fuentes = ((body['fuentes'] as List?) ?? [])
        .map((f) => Fuente.fromJson(f as Map<String, dynamic>))
        .toList();
    final actions = TreatmentActions(
      quimico: entry['quimico'] as String? ?? '',
      cultural: entry['cultural'] as String? ?? '',
      biologico: entry['biologico'] as String? ?? '',
      preventivo: entry['preventivo'] as String? ?? '',
      fuentes: fuentes,
    );
    return (actions, entry['urgencia'] as String? ?? 'media');
  }

  String _applyClimateModifier(DiseaseFinding finding, ClimateData? climate) {
    if (climate == null) return finding.severityLevel;
    final shift = _climateShift(finding.pathogenClass, climate);
    final base = _rankSeverity(finding.severityLevel);
    final shifted = (base + shift).clamp(0, _severityOrder.length - 1);
    return _severityOrder[shifted];
  }

  int _climateShift(String pathogenClass, ClimateData c) {
    final cls = _resolveKey(pathogenClass);
    final t = c.tempC;
    final h = c.humidity;
    final p = c.precipMm;
    return switch (cls) {
      'roya' when h > 80 && t >= 20 && t <= 28 => 1,
      'roya' when h < 50 => -1,
      'fungicas' when h > 75 => 1,
      'bacterianas' when p > 3 => 1,
      'virales' when t > 28 => 1,
      'plagas_insectos' when t >= 24 && t <= 32 => 1,
      _ => 0,
    };
  }

  String _rationaleFor(
    DiseaseFinding finding,
    String adjustedLevel,
    ClimateData? climate,
  ) {
    final coverage = finding.coveragePct.toStringAsFixed(0);
    final base =
        '${coverage}% del área foliar afectada · severidad promedio ${finding.avgSeverityPct.toStringAsFixed(1)}%';
    if (climate != null && adjustedLevel != finding.severityLevel) {
      return '$base · urgencia escalada por clima favorable';
    }
    return base;
  }

  List<String> _findWarnings(List<TreatmentPriority> priorities) {
    if (priorities.length < 2) return const [];
    final lowered = priorities
        .map((p) => '${p.actions.quimico} ${p.actions.cultural}'.toLowerCase())
        .toList();
    final hits = <String>[];
    for (final inc in _incompatibilities) {
      final present = inc.productos.where((prod) {
        return lowered.any((text) => text.contains(prod.toLowerCase()));
      }).toList();
      if (present.length >= 2) {
        hits.add('Evitar combinar ${inc.productos.join(" + ")}: ${inc.razon}');
      }
    }
    return hits;
  }

  String? _shortestVentana(List<TreatmentPriority> priorities) {
    if (priorities.isEmpty) return null;
    final worst = priorities
        .map((p) => p.severityLevel)
        .reduce((a, b) => _rankSeverity(a) >= _rankSeverity(b) ? a : b);
    return _ventanas[worst];
  }

  int _rankSeverity(String level) => _severityRank[normalizeKey(level)] ?? 2;

  String? _climateGuidance(ClimateData c) {
    final parts = <String>[];
    if (c.humidity > 80) {
      parts.add('Humedad ${c.humidity.toStringAsFixed(0)}% — aplicar al amanecer para evitar dispersión por rocío nocturno');
    }
    if (c.tempC > 32) {
      parts.add('Temperatura ${c.tempC.toStringAsFixed(1)}°C — evitar mediodía; aplicar antes de las 9h o después de las 17h');
    }
    if (c.precipMm > 3) {
      parts.add('Lluvia reciente ${c.precipMm.toStringAsFixed(1)} mm — adelantar aplicación 24h para anticipar siguiente lluvia');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

class _Incompatibility {
  final List<String> productos;
  final String razon;

  const _Incompatibility({required this.productos, required this.razon});

  factory _Incompatibility.fromJson(Map<String, dynamic> json) => _Incompatibility(
        productos: (json['productos'] as List).map((e) => e.toString()).toList(),
        razon: json['razon'] as String,
      );
}
