import 'package:alertaya/features/panic/domain/entities/panic_session_entity.dart';

class PanicSessionModel {
  static PanicSessionEntity fromJson(Map<String, dynamic> json) =>
      PanicSessionEntity(
        id: json['id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        status: json['status'] as String? ?? 'ACTIVE',
      );
}
