import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../domain/ClimateData.dart';
import '../domain/DiagnoseResult.dart';
import '../domain/Diagnoser.dart';
import '../domain/DiseaseFinding.dart';
import '../domain/OnsetEstimate.dart';
import '../domain/Protocols.dart';
import '../domain/Zone.dart';

class HttpDiagnoser implements Diagnoser {
  static const int _maxSide = 400;
  static const int _jpegQuality = 85;

  final String endpoint;
  final TreatmentRepository treatments;
  final OnsetEstimator onsetEstimator;

  const HttpDiagnoser({
    required this.endpoint,
    required this.treatments,
    required this.onsetEstimator,
  });

  @override
  Future<DiagnoseResult> diagnose(XFile image, {double? lat, double? lon}) async {
    final compressed = await _compress(image);

    final request = http.MultipartRequest('POST', Uri.parse(endpoint))
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        compressed.bytes,
        filename: 'image.jpg',
      ));
    if (lat != null) request.fields['lat'] = lat.toString();
    if (lon != null) request.fields['lon'] = lon.toString();

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Servidor: ${streamed.statusCode} $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return _parseResult(json, compressed.width, compressed.height);
  }

  DiagnoseResult _parseResult(Map<String, dynamic> json, int width, int height) {
    final zones = (json['zonas'] as List? ?? [])
        .map((e) => Zone.fromJson(e as Map<String, dynamic>))
        .toList();
    final findings = (json['enfermedades_detectadas'] as List? ?? [])
        .map((e) => DiseaseFinding.fromJson(e as Map<String, dynamic>))
        .toList();
    final climateRaw = json['climate'] as Map<String, dynamic>?;
    final climate = climateRaw == null ? null : ClimateData.fromJson(climateRaw);
    final patchSize = (json['patch_size'] as num?)?.toInt() ?? 150;
    final totalPatches = (json['total_patches'] as num?)?.toInt() ?? 0;
    final leafPatches = (json['leaf_patches'] as num?)?.toInt() ?? totalPatches;
    final onset = _resolveOnset(findings, climate);
    final plan = treatments.buildComposite(findings: findings, climate: climate);

    return DiagnoseResult(
      zones: zones,
      findings: findings,
      imageWidth: width,
      imageHeight: height,
      patchSize: patchSize,
      totalPatches: totalPatches,
      leafPatches: leafPatches,
      climate: climate,
      onset: onset,
      treatmentPlan: plan,
    );
  }

  OnsetEstimate? _resolveOnset(List<DiseaseFinding> findings, ClimateData? climate) {
    if (findings.isEmpty) return null;
    final worst = findings.first;
    return onsetEstimator.estimate(
      pathogenClass: worst.pathogenClass,
      severityLevel: worst.severityLevel,
      climate: climate,
    );
  }

  static Future<_CompressedImage> _compress(XFile imageFile) async {
    final raw = await imageFile.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      return _CompressedImage(Uint8List.fromList(raw), 0, 0);
    }
    var image = decoded;
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest > _maxSide) {
      final scale = _maxSide / longest;
      image = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
    }
    final bytes = Uint8List.fromList(img.encodeJpg(image, quality: _jpegQuality));
    return _CompressedImage(bytes, image.width, image.height);
  }
}

class _CompressedImage {
  final Uint8List bytes;
  final int width;
  final int height;

  const _CompressedImage(this.bytes, this.width, this.height);
}
