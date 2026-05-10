const Map<String, String> _labelEs = {
  'healthy': 'Sana',
  'diseased': 'Enferma',
  'bacterial_diseases': 'Bacterianas',
  'fungal_diseases': 'Fúngicas',
  'rust_disease': 'Roya',
  'insect_pests': 'Plagas de insectos',
  'viral_diseases': 'Virales',
};

String labelToEs(String label) =>
    _labelEs[label.toLowerCase().replaceAll(' ', '_')] ?? label;
