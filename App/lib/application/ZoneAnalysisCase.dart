import 'package:image_picker/image_picker.dart';
import '../domain/Protocols.dart';
import '../domain/ZoneAnalysis.dart';

class AnalyzeZonesUseCase {
  final ZoneAnalyzer analyzer;

  const AnalyzeZonesUseCase(this.analyzer);

  Future<ZoneAnalysis> execute(XFile image, {double? lat, double? lon}) =>
      analyzer.analyze(image, lat: lat, lon: lon);
}
