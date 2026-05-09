import 'package:alertaya/features/alerts/domain/entities/notification_entity.dart';

class NotificationModel {
  static NotificationEntity fromJson(Map<String, dynamic> json) =>
      NotificationEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        incidentId: json['incidentId'] as String?,
        district: json['district'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
