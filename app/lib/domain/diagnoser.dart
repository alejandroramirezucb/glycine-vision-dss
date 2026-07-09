import 'package:image_picker/image_picker.dart';
import 'diagnose_result.dart';

abstract class Diagnoser {
  Future<DiagnoseResult> diagnose(
    XFile image, {
    double? lat,
    double? lon,
    double fieldAreaHa = 1.0,
    DateTime? onsetDate,
  });
}
