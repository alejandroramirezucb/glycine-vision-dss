const Map<String, String> _labelEs = {
  'soya_enferma': 'Enferma',
  'soya_sana': 'Sana',
  'bacterianas': 'Bacterianas',
  'fungicas': 'Fúngicas',
  'roya': 'Roya',
  'plagas_insectos': 'Plagas de insectos',
  'virales': 'Virales',
};

const Map<String, String> _severityEs = {
  'minima': 'Mínima',
  'leve': 'Leve',
  'moderada': 'Moderada',
  'severa': 'Severa',
  'critica': 'Crítica',
};

String labelToEs(String label) =>
    _labelEs[label.toLowerCase().replaceAll(' ', '_')] ?? label;

String severityToEs(String level) =>
    _severityEs[level.toLowerCase()] ?? level;
