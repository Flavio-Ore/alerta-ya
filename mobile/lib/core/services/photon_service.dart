import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Sugerencia de dirección devuelta por la API Photon (Komoot).
/// https://photon.komoot.io — Servicio público, sin API key.
class PhotonSuggestion {
  const PhotonSuggestion({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  final String displayName;
  final double lat;
  final double lng;
}

/// Resultado de una búsqueda Photon — distingue resultado válido de error.
sealed class PhotonResult {
  const PhotonResult();
}

class PhotonSuccess extends PhotonResult {
  const PhotonSuccess(this.suggestions);
  final List<PhotonSuggestion> suggestions;
}

class PhotonNetworkError extends PhotonResult {
  const PhotonNetworkError();
}

/// Servicio de geocodificación directa mediante Photon (Komoot).
/// Usa su propio cliente Dio — NO requiere autenticación ni el Dio del API.
class PhotonService {
  PhotonService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://photon.komoot.io',
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 12),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'AlertaYa/1.0 (pe.alertaya.app)',
            },
          ),
        );

  final Dio _dio;

  /// Devuelve hasta [limit] sugerencias para [query] o un error tipado.
  /// [lat] y [lng] sirven como hint geográfico (prioriza resultados cercanos).
  Future<PhotonResult> suggest(
    String query, {
    double? lat,
    double? lng,
    int limit = 6,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const PhotonSuccess([]);

    try {
      final params = <String, dynamic>{
        // Appending "Lima" da mejores resultados dentro de Perú.
        // OJO: Photon NO soporta lang=es (solo de/en/fr/it).
        // Sin lang= devuelve los nombres en idioma local del lugar (español acá).
        'q': '$q Lima Perú',
        'limit': limit,
      };
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lon'] = lng;

      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/',
        queryParameters: params,
      );

      final features = resp.data!['features'] as List<dynamic>;

      final suggestions = features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final coords = (f['geometry'] as Map)['coordinates'] as List<dynamic>;

        final nameParts = <String>[
          if (props['name'] != null) props['name'] as String,
          if (props['street'] != null) props['street'] as String,
          if (props['city'] != null)
            props['city'] as String
          else if (props['county'] != null)
            props['county'] as String,
        ];

        return PhotonSuggestion(
          displayName: nameParts.isEmpty ? q : nameParts.join(', '),
          lat: (coords[1] as num).toDouble(),
          lng: (coords[0] as num).toDouble(),
        );
      }).toList();

      return PhotonSuccess(suggestions);
    } on DioException catch (e) {
      developer.log(
        'DioException type=${e.type} '
        'msg=${e.message} status=${e.response?.statusCode}',
        name: 'PhotonService',
      );
      return const PhotonNetworkError();
    } catch (e, stack) {
      developer.log(
        'unexpected: $e',
        name: 'PhotonService',
        error: e,
        stackTrace: stack,
      );
      return const PhotonNetworkError();
    }
  }

  /// Reverse-geocode lat/lng → dirección legible "Av. Larco, Miraflores".
  /// Devuelve null si falla (network/no results) — el caller debe fallback al distrito.
  /// Endpoint: https://photon.komoot.io/reverse?lat=X&lon=Y
  Future<String?> reverse({required double lat, required double lng}) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {'lat': lat, 'lon': lng, 'limit': 1},
      );
      final features = resp.data!['features'] as List<dynamic>;
      if (features.isEmpty) return null;
      final props = features.first['properties'] as Map<String, dynamic>;

      // Preferir street; si no hay, name. Agregar city/county si disponible.
      final street = props['street'] as String? ?? props['name'] as String?;
      final city = props['city'] as String? ?? props['county'] as String?;
      if (street == null && city == null) return null;
      if (street == null) return city;
      if (city == null) return street;
      return '$street, $city';
    } catch (e) {
      developer.log('reverse failed: $e', name: 'PhotonService');
      return null;
    }
  }
}
