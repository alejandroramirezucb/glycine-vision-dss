import '../domain/ClimateData.dart';
import '../domain/OnsetEstimate.dart';
import '../domain/Protocols.dart';

class EstimateOnsetUseCase {
  final OnsetEstimator estimator;

  const EstimateOnsetUseCase(this.estimator);

  OnsetEstimate? execute({
    required String? pathogenClass,
    required String? severityLevel,
    ClimateData? climate,
  }) {
    if (pathogenClass == null || severityLevel == null) return null;
    return estimator.estimate(
      pathogenClass: pathogenClass,
      severityLevel: severityLevel,
      climate: climate,
    );
  }
}
