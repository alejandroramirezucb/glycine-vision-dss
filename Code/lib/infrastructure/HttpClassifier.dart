import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../domain/Entities.dart';
import '../domain/Protocols.dart';

class HttpClassifier implements ImageClassifier {
  final String _endpoint;

  const HttpClassifier(this._endpoint);

  @override
  Future<PredictionResult> classify(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: imageFile.name.isNotEmpty ? imageFile.name : 'image.jpg',
    ));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;

    if (json.containsKey('error')) throw Exception(json['error']);

    final predictions = (json['predictions'] as List)
        .map((p) => PredictionItem(
              label: p['label'] as String,
              confidence: (p['confidence'] as num).toDouble(),
            ))
        .toList();

    return PredictionResult(predictions: predictions, imagePath: imageFile.path);
  }
}
