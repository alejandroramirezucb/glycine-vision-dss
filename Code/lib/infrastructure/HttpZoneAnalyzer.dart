import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../domain/Protocols.dart';
import '../domain/ZoneAnalysis.dart';

class HttpZoneAnalyzer implements ZoneAnalyzer {
  final String endpoint;

  const HttpZoneAnalyzer(this.endpoint);

  @override
  Future<ZoneAnalysis> analyze(XFile imageFile, {double? lat, double? lon}) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    final w = decoded?.width ?? 0;
    final h = decoded?.height ?? 0;

    final uri = Uri.parse(endpoint);
    final req = http.MultipartRequest('POST', uri);
    req.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: imageFile.name,
    ));
    if (lat != null) req.fields['lat'] = lat.toString();
    if (lon != null) req.fields['lon'] = lon.toString();

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Servidor: ${streamed.statusCode} $body');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return ZoneAnalysis.fromJson(json, width: w, height: h);
  }
}
