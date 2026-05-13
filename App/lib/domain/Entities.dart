class PredictionItem {
  final String label;
  final double confidence;

  const PredictionItem({required this.label, required this.confidence});
}

class PredictionResult {
  final List<PredictionItem> predictions;
  final String imagePath;

  const PredictionResult({required this.predictions, required this.imagePath});

  PredictionItem get topPrediction => predictions.isNotEmpty
      ? predictions.first
      : const PredictionItem(label: '', confidence: 0);
}
