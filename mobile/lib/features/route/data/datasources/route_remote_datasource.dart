import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/route/domain/entities/route_option_entity.dart';

class RouteRemoteDatasource {
  RouteRemoteDatasource()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;

  static const _osrmBase =
      'https://router.project-osrm.org/route/v1/driving';

  // Incidentes dentro de este radio contribuyen al riesgo de la ruta
  static const _nearbyThresholdMeters = 300.0;

  Future<List<RouteOptionEntity>> compareRoutes({
    required LatLng origin,
    required LatLng destination,
    required List<IncidentEntity> incidents,
  }) async {
    final url = '$_osrmBase/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?alternatives=true&overview=full&geometries=geojson';

    final response = await _dio.get<Map<String, dynamic>>(url);
    final routes = response.data!['routes'] as List<dynamic>;

    return routes.asMap().entries.map((entry) {
      final label = String.fromCharCode(65 + entry.key); // A, B, C...
      final route = entry.value as Map<String, dynamic>;

      final coords = ((route['geometry'] as Map<String, dynamic>)['coordinates'] as List<dynamic>)
          .map((c) {
            final pair = c as List<dynamic>;
            return LatLng(pair[1] as double, pair[0] as double);
          })
          .toList();

      final duration = (route['duration'] as num).toInt();
      final distance = (route['distance'] as num).toDouble();
      final nearby = _nearbyIncidents(coords, incidents);
      final risk = _riskScore(nearby);

      return RouteOptionEntity(
        label: label,
        polyline: coords,
        durationSeconds: duration,
        distanceMeters: distance,
        riskScore: risk,
        nearbyIncidents: nearby,
      );
    }).toList();
  }

  List<IncidentEntity> _nearbyIncidents(
    List<LatLng> polyline,
    List<IncidentEntity> incidents,
  ) {
    const distance = Distance();
    return incidents.where((incident) {
      final point = LatLng(incident.lat, incident.lng);
      return polyline
          .any((p) => distance(p, point) <= _nearbyThresholdMeters);
    }).toList();
  }

  int _riskScore(List<IncidentEntity> nearby) {
    if (nearby.isEmpty) return 0;
    int raw = 0;
    for (final inc in nearby) {
      raw += switch (inc.severity) {
        Severity.critical => 30,
        Severity.moderate => 10,
        Severity.low => 3,
      };
    }
    return raw.clamp(0, 100);
  }
}
