/// Un punto del mapa de calor de riesgo cercano al usuario.
class RiskTile {
  const RiskTile({
    required this.lat,
    required this.lng,
    required this.risk,
  });

  factory RiskTile.fromJson(Map<String, dynamic> json) => RiskTile(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        risk: (json['risk'] as num).toDouble(),
      );

  final double lat;
  final double lng;
  final double risk;
}

/// Snapshot de riesgo espaciotemporal para una ubicación + hora dadas.
///
/// Reflejo del contrato `GET /risk` — ver `api/src/features/risk/`.
/// Fail-open: `riskScore` puede ser null y `level` puede ser 'unknown'
/// cuando no hay datos suficientes; la UI nunca debe crashear en ese caso.
class RiskInfo {
  const RiskInfo({
    required this.district,
    required this.hour,
    required this.riskScore,
    required this.level,
    required this.topType,
    required this.confidence,
    required this.badHours,
    required this.nearbyTiles,
  });

  factory RiskInfo.fromJson(Map<String, dynamic> json) => RiskInfo(
        district: json['district'] as String,
        hour: json['hour'] as int,
        riskScore: (json['riskScore'] as num?)?.toInt(),
        level: json['level'] as String,
        topType: json['topType'] as String?,
        confidence: json['confidence'] as String,
        badHours: (json['badHours'] as List<dynamic>)
            .map((h) => h as int)
            .toList(),
        nearbyTiles: (json['nearbyTiles'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(RiskTile.fromJson)
            .toList(),
      );

  final String district;
  final int hour;
  final int? riskScore;
  final String level;
  final String? topType;
  final String confidence;
  final List<int> badHours;
  final List<RiskTile> nearbyTiles;

  bool get hasData => level != 'unknown' && riskScore != null;
}
