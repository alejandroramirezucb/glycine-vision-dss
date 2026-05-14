import 'package:image_picker/image_picker.dart';
import '../domain/DiagnoseResult.dart';
import '../domain/Diagnoser.dart';

class DiagnoseUseCase {
  final Diagnoser _diagnoser;

  const DiagnoseUseCase(this._diagnoser);

  Future<DiagnoseResult> execute(XFile image, {double? lat, double? lon}) =>
      _diagnoser.diagnose(image, lat: lat, lon: lon);
}
