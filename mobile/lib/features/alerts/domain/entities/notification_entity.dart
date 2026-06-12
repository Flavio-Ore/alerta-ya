import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_entity.freezed.dart';

@freezed
class NotificationEntity with _$NotificationEntity {
  const factory NotificationEntity({
    required String id,
    required String title,
    required String body,
    String? incidentId,
    required String district,
    required bool isRead,
    required DateTime createdAt,
  }) = _NotificationEntity;
}
