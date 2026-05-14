class TfliteClassifier {
  TfliteClassifier._();

  static Future<TfliteClassifier> load({
    required String modelAsset,
    required String labelsAsset,
    String? thresholdsAsset,
    int inputSize = 224,
  }) async {
    throw UnsupportedError('TfliteClassifier no disponible en web');
  }

  List<String> get labels => const [];
  double thresholdFor(String label) => 0.5;
  List<double> run(Object image) =>
      throw UnsupportedError('TfliteClassifier no disponible en web');
}
