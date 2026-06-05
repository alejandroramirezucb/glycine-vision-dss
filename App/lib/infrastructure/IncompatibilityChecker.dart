import '../domain/Incompatibility.dart';
import '../domain/TreatmentPlan.dart';

class IncompatibilityChecker {
  final List<Incompatibility> _rules;

  const IncompatibilityChecker(this._rules);

  List<String> findWarnings(List<TreatmentPriority> priorities) {
    if (priorities.length < 2) return const [];
    final texts = priorities
        .map((p) => '${p.actions.chemical} ${p.actions.cultural}'.toLowerCase())
        .toList();
    final hits = <String>[];
    for (final rule in _rules) {
      final present = rule.products
          .where((prod) => texts.any((t) => t.contains(prod.toLowerCase())))
          .toList();
      if (present.length >= 2)
        hits.add('Avoid combining ${rule.products.join(' + ')}: ${rule.reason}');
    }
    return hits;
  }
}
