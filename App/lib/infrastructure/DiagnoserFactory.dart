import 'package:flutter/foundation.dart';
import '../domain/Diagnoser.dart';
import '../domain/Protocols.dart';
import 'Classifier.dart'
    if (dart.library.js_interop) 'ClassifierWebStub.dart';
import 'HttpDiagnoser.dart';
import 'LocalDiagnoser.dart'
    if (dart.library.js_interop) 'LocalDiagnoserWebStub.dart';
import 'OnsetEstimatorImpl.dart';
import 'TfliteSegmenter.dart'
    if (dart.library.js_interop) 'TfliteSegmenterWebStub.dart';

const _serverBase = 'http://localhost:8001';

class DiagnoserFactory {
  static Future<Diagnoser> build({
    required TreatmentRepository treatments,
    required ClimateRepository climateRepo,
  }) async {
    const onsetEstimator = OnsetEstimatorImpl();
    if (kIsWeb)
      return HttpDiagnoser(
        endpoint: '$_serverBase/api/diagnose',
        treatments: treatments,
        onsetEstimator: onsetEstimator,
      );

    final healthModel = await TfliteClassifier.load(
      modelAsset: 'assets/models/hs/model.tflite',
      labelsAsset: 'assets/models/hs/labels.txt',
      inputSize: 240,
    );
    final diseaseModel = await TfliteClassifier.load(
      modelAsset: 'assets/models/pd/model_unquant.tflite',
      labelsAsset: 'assets/models/pd/labels.txt',
      thresholdsAsset: 'assets/models/pd/thresholds.json',
    );
    TfliteSegmenter? segmenter;
    try {
      segmenter = await TfliteSegmenter.load(
        modelAsset: 'assets/models/seg/model_seg.tflite',
      );
    } catch (_) {}
    return LocalDiagnoser(
      healthModel: healthModel,
      diseaseModel: diseaseModel,
      segmenter: segmenter,
      treatments: treatments,
      climateRepo: climateRepo,
      onsetEstimator: onsetEstimator,
    );
  }
}
