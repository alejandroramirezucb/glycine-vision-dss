import '../domain/ClimateData.dart';
import '../domain/Protocols.dart';

class FetchClimateUseCase {
  final ClimateRepository repository;

  const FetchClimateUseCase(this.repository);

  Future<ClimateData?> execute(double lat, double lon) =>
      repository.fetch(lat, lon);
}
