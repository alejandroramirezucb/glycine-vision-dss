import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/Protocols.dart';
import '../domain/Treatment.dart';

class JsonTreatmentRepository implements TreatmentRepository {
  final Map<String, TreatmentInfo> _treatments = {};

  static const _labelMap = {
    'bacterial_diseases': 'Bacterianas',
    'fungal_diseases': 'Fungicas',
    'rust_disease': 'Roya',
    'viral_diseases': 'Virales',
    'insect_pests': 'Plagas_Insectos',
  };

  static Future<JsonTreatmentRepository> load() async {
    final repo = JsonTreatmentRepository();
    final jsonText =
        await rootBundle.loadString('assets/data/tratamientos.json');
    final json = jsonDecode(jsonText) as Map<String, dynamic>;

    for (final entry in json.entries) {
      final treatment =
          TreatmentInfo.fromJson(entry.key, entry.value as Map<String, dynamic>);
      repo._treatments[entry.key] = treatment;
      if (_labelMap.containsValue(entry.key)) {
        final key =
            _labelMap.entries.firstWhere((e) => e.value == entry.key).key;
        repo._treatments[key] = treatment;
      }
    }

    return repo;
  }

  @override
  TreatmentInfo? getByLabel(String label) {
    final normalized = label.trim().toLowerCase().replaceAll(' ', '_');
    final mapped = _labelMap[normalized] ?? normalized;
    return _treatments[mapped];
  }
}
