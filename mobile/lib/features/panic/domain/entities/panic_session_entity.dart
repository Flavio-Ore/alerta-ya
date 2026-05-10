import 'package:freezed_annotation/freezed_annotation.dart';

part 'panic_session_entity.freezed.dart';

@freezed
class PanicSessionEntity with _$PanicSessionEntity {
  const factory PanicSessionEntity({
    required String id,
    required double lat,
    required double lng,
    required DateTime startedAt,
    DateTime? endedAt,
    @Default('ACTIVE') String status,
  }) = _PanicSessionEntity;
}
