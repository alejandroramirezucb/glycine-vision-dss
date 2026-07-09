import 'package:flutter/foundation.dart';
import '../domain/diagnoser.dart';
import '../domain/protocols.dart';
import 'classifier.dart'
    if (dart.library.js_interop) 'classifier_web_stub.dart';
import 'http_diagnoser.dart';
import 'local_diagnoser.dart'
    if (dart.library.js_interop) 'local_diagnoser_web_stub.dart';
import 'onset_estimator_impl.dart';
import 'tflite_segmenter.dart'
    if (dart.library.js_interop) 'tflite_segmenter_web_stub.dart';

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
