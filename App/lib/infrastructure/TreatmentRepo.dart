import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/ClimateData.dart';
import '../domain/DiseaseFinding.dart';
import '../domain/Incompatibility.dart';
import '../domain/Protocols.dart';
import '../domain/StringNormalizer.dart';
import '../domain/Treatment.dart';
import '../domain/TreatmentPlan.dart';
import 'ClimateSeverityAdjuster.dart';
import 'IncompatibilityChecker.dart';

class JsonTreatmentRepository implements TreatmentRepository {
  static const double _minCoveragePct = 5.0;
  static const Map<String, int> _severityRank = {
    'minima': 0, 'leve': 1, 'moderada': 2, 'severa': 3, 'critica': 4,
  };
  static const Map<String, String> _keyAliases = {
    'bacterial_diseases': 'bacterianas',
    'fungal_diseases': 'fungicas',
    'rust_disease': 'roya',
    'viral_diseases': 'virales',
    'insect_pests': 'plagas_insectos',
  };

  final Map<String, Map<String, dynamic>> _diseaseData;
  final IncompatibilityChecker _checker;
  final Map<String, String> _applicationWindows;
  final ClimateSeverityAdjuster _adjuster;

  JsonTreatmentRepository._(
    this._diseaseData,
    this._checker,
    this._applicationWindows,
    this._adjuster,
  );

  static Future<JsonTreatmentRepository> load() async {
    final root = jsonDecode(
      await rootBundle.loadString('assets/data/tratamientos.json'),
    ) as Map<String, dynamic>;
    final meta = root['_meta'] as Map<String, dynamic>? ?? {};
    final incompatibilities = _parseIncompatibilities(meta);
    final windows = _parseWindows(meta);
    final diseases = <String, Map<String, dynamic>>{};
    for (final entry in root.entries) {
      if (entry.key == '_meta') continue;
      diseases[entry.key] = entry.value as Map<String, dynamic>;
    }
    return JsonTreatmentRepository._(
      diseases,
      IncompatibilityChecker(incompatibilities),
      windows,
      ClimateSeverityAdjuster(),
    );
  }

  static List<Incompatibility> _parseIncompatibilities(Map<String, dynamic> meta) {
    final raw = meta['incompatibilities'] as List? ?? [];
    return raw.map((e) => Incompatibility.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Map<String, String> _parseWindows(Map<String, dynamic> meta) {
    final raw = meta['application_windows'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, v.toString()));
  }

  @override
  TreatmentPlan buildComposite({
    required List<DiseaseFinding> findings,
    ClimateData? climate,
    double fieldAreaHa = 1.0,
  }) {
    final relevant = findings.where((f) => f.coveragePct >= _minCoveragePct).toList();
    if (relevant.isEmpty)
      return const TreatmentPlan(priorities: [], warnings: []);

    final priorities = relevant
        .map((f) => _buildPriority(f, climate))
        .whereType<TreatmentPriority>()
        .toList()
      ..sort((a, b) => _rank(b.severityLevel).compareTo(_rank(a.severityLevel)));

    return TreatmentPlan(
      priorities: priorities,
      warnings: _checker.findWarnings(priorities),
      applicationWindow: _worstWindow(priorities),
      climateGuidance: climate == null ? null : _climateGuidance(climate),
    );
  }

  TreatmentPriority? _buildPriority(DiseaseFinding finding, ClimateData? climate) {
    final key = _resolveKey(finding.pathogenClass);
    final body = _diseaseData[key];
    if (body == null) return null;
    final level = _adjuster.adjust(finding.severityLevel, key, climate);
    final actions = _readActions(body, level);
    if (actions == null) return null;
    return TreatmentPriority(
      pathogenClass: key,
      severityLevel: level,
      rationale: _rationale(finding, level, climate),
      actions: actions,
    );
  }

  String _resolveKey(String label) {
    final norm = normalizeKey(label);
    return _keyAliases[norm] ?? _keyAliases[label] ?? norm;
  }

  TreatmentActions? _readActions(Map<String, dynamic> body, String severity) {
    final bySeverity = body['by_severity'] as Map<String, dynamic>?
        ?? body['por_severidad'] as Map<String, dynamic>?;
    if (bySeverity == null) return null;
    final entry = bySeverity[severity] as Map<String, dynamic>?
        ?? bySeverity['moderada'] as Map<String, dynamic>?
        ?? bySeverity.values.first as Map<String, dynamic>;
    final rawRefs = ((body['references'] as List?) ?? (body['fuentes'] as List?) ?? []);
    final refs = rawRefs.map((f) => Reference.fromJson(f as Map<String, dynamic>)).toList();
    return TreatmentActions(
      chemical: _resolveChemical(entry),
      cultural: entry['cultural'] as String? ?? '',
      biological: _resolveBiological(entry),
      preventive: entry['preventive'] as String? ?? entry['preventivo'] as String? ?? '',
      references: refs,
    );
  }

  String _resolveChemical(Map<String, dynamic> entry) {
    final chem = entry['chemical'];
    if (chem is Map<String, dynamic>) {
      final product = chem['product'] as String? ?? '';
      final dose = chem['dose_g_per_100L'];
      return dose != null ? '$product — ${dose}g/100 L' : product;
    }
    return entry['quimico'] as String? ?? '';
  }

  String _resolveBiological(Map<String, dynamic> entry) {
    final bio = entry['biological'];
    if (bio is Map<String, dynamic>) {
      final agent = bio['agent'] as String? ?? '';
      final dose = bio['dose_mL_per_100L'];
      return dose != null ? '$agent — ${dose}mL/100 L' : agent;
    }
    return entry['biologico'] as String? ?? '';
  }

  String _rationale(DiseaseFinding f, String level, ClimateData? climate) {
    final coverage = f.coveragePct.toStringAsFixed(0);
    final base = '${coverage}% leaf area · avg severity ${f.avgSeverityPct.toStringAsFixed(1)}%';
    return (climate != null && level != f.severityLevel)
        ? '$base · urgency escalated by climate'
        : base;
  }

  String? _worstWindow(List<TreatmentPriority> priorities) {
    if (priorities.isEmpty) return null;
    final worst = priorities
        .map((p) => p.severityLevel)
        .reduce((a, b) => _rank(a) >= _rank(b) ? a : b);
    return _applicationWindows[worst];
  }

  int _rank(String level) => _severityRank[normalizeKey(level)] ?? 2;

  String? _climateGuidance(ClimateData c) {
    final parts = <String>[];
    if (c.humidity > 80)
      parts.add('Humidity ${c.humidity.toStringAsFixed(0)}% — apply at dawn to prevent dew spread');
    if (c.tempC > 32)
      parts.add('Temperature ${c.tempC.toStringAsFixed(1)}°C — avoid midday; apply before 9h or after 17h');
    if (c.precipMm > 3)
      parts.add('Recent rain ${c.precipMm.toStringAsFixed(1)} mm — advance application by 24h');
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
