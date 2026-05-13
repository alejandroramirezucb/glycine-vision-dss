import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/ClimateData.dart';
import '../domain/Protocols.dart';

class OpenMeteoClient implements ClimateRepository {
  static const _base = 'https://api.open-meteo.com/v1/forecast';
  final Duration _cacheTtl;
  final Map<String, _CachedClimate> _cache = {};

  OpenMeteoClient({Duration cacheTtl = const Duration(minutes: 30)})
      : _cacheTtl = cacheTtl;

  @override
  Future<ClimateData?> fetch(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.data;
    }
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,precipitation,dew_point_2m',
        'timezone': 'auto',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = body['current'] as Map<String, dynamic>? ?? {};
      final data = ClimateData(
        tempC: (cur['temperature_2m'] as num? ?? 0).toDouble(),
        humidity: (cur['relative_humidity_2m'] as num? ?? 0).toDouble(),
        precipMm: (cur['precipitation'] as num? ?? 0).toDouble(),
        dewpointC: (cur['dew_point_2m'] as num? ?? 0).toDouble(),
        fetchedAt: DateTime.now(),
      );
      _cache[key] = _CachedClimate(data, DateTime.now());
      return data;
    } catch (_) {
      return null;
    }
  }
}

class _CachedClimate {
  final ClimateData data;
  final DateTime at;
  const _CachedClimate(this.data, this.at);
}
