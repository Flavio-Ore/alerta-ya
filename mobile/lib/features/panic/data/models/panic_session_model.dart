import 'package:alertaya/features/panic/domain/entities/panic_session_entity.dart';
import 'package:alertaya/features/panic/domain/entities/panic_start_result.dart';

class PanicSessionModel {
  static PanicStartResult fromJsonFull(Map<String, dynamic> json) {
    final entity = PanicSessionEntity(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'ACTIVE',
    );

    final params = (json['uploadParams'] as List<dynamic>? ?? [])
        .map((e) => CloudinaryUploadParams.fromJson(e as Map<String, dynamic>))
        .toList();

    return PanicStartResult(session: entity, uploadParams: params);
  }
}
