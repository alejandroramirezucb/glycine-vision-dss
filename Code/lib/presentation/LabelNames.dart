const Map<String, String> _labelEs = {
  'healthy': 'Sana',
  'diseased': 'Enferma',
  'soya_sana': 'Sana',
  'soya_enferma': 'Enferma',
  'bacterial_diseases': 'Bacterianas',
  'fungal_diseases': 'Fúngicas',
  'rust_disease': 'Roya',
  'insect_pests': 'Plagas de insectos',
  'viral_diseases': 'Virales',
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
