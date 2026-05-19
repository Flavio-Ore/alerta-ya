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
    @Default(1) int currentBlock,
    @Default([]) List<String> recordingPaths,
  }) = _PanicSessionEntity;
}
