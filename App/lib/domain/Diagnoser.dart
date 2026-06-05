import 'package:image_picker/image_picker.dart';
import 'DiagnoseResult.dart';

abstract class Diagnoser {
  Future<DiagnoseResult> diagnose(
    XFile image, {
    double? lat,
    double? lon,
    double fieldAreaHa = 1.0,
  });
}
