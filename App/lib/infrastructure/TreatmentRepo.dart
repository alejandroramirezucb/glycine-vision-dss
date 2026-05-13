import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/Protocols.dart';
import '../domain/StringNormalizer.dart';
import '../domain/Treatment.dart';

class JsonTreatmentRepository implements TreatmentRepository {
  final Map<String, TreatmentInfo> _default = {};
  final Map<String, Map<String, TreatmentInfo>> _bySeverity = {};

  static const _labelMap = {
    'bacterial_diseases': 'bacterianas',
    'fungal_diseases': 'fungicas',
    'rust_disease': 'roya',
    'viral_diseases': 'virales',
    'insect_pests': 'plagas_insectos',
    'Bacterianas': 'bacterianas',
    'Fungicas': 'fungicas',
    'Roya': 'roya',
    'Virales': 'virales',
    'Plagas_Insectos': 'plagas_insectos',
  };

  static Future<JsonTreatmentRepository> load() async {
    final repo = JsonTreatmentRepository();
    final jsonText = await rootBundle.loadString('assets/data/tratamientos.json');
    final json = jsonDecode(jsonText) as Map<String, dynamic>;

    for (final entry in json.entries) {
      final key = entry.key;
      final body = entry.value as Map<String, dynamic>;
      final defaultInfo = TreatmentInfo.fromJson(key, body);
      repo._default[key] = defaultInfo;
      repo._default[normalizeKey(key)] = defaultInfo;

      final porSev = body['por_severidad'] as Map<String, dynamic>?;
      if (porSev != null) {
        final map = <String, TreatmentInfo>{};
        porSev.forEach((nivel, sevBody) {
          map[normalizeKey(nivel)] = TreatmentInfo.fromSeverityEntry(
            key,
            body,
            sevBody as Map<String, dynamic>,
          );
        });
        repo._bySeverity[normalizeKey(key)] = map;
      }
    }

    return repo;
  }

  @override
  TreatmentInfo? getByLabel(String label) {
    final norm = normalizeKey(label);
    final mapped = _labelMap[label] ?? _labelMap[norm] ?? norm;
    return _default[mapped] ?? _default[label];
  }

  @override
  TreatmentInfo? getByLabelAndSeverity(String label, String severityLevel) {
    final norm = normalizeKey(label);
    final mapped = _labelMap[label] ?? _labelMap[norm] ?? norm;
    final bySev = _bySeverity[mapped];
    if (bySev == null) return getByLabel(label);
    return bySev[normalizeKey(severityLevel)] ?? getByLabel(label);
  }
}
