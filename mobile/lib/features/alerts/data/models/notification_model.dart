import 'package:alertaya/features/alerts/domain/entities/notification_entity.dart';

class NotificationModel {
  static NotificationEntity fromJson(Map<String, dynamic> json) =>
      NotificationEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        incidentId: json['incidentId'] as String?,
        // district no viene de la API — se deja vacío
        district: '',
        // API devuelve readAt: ISO string | null (no isRead bool)
        isRead: json['readAt'] != null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
