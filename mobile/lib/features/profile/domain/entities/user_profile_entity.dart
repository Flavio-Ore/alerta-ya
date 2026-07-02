/// Datos no sensibles del usuario autenticado devueltos por GET /me/profile.
/// Nombre y foto quedan en Firebase Auth en el cliente — nunca van al API.
class UserProfileEntity {
  const UserProfileEntity({
    required this.reputationScore,
    required this.memberSince,
    this.tier,
    this.pointsToNext,
  });

  /// Puntuación de reputación (gamificación). Default 100.
  final int reputationScore;

  /// Fecha de alta en la plataforma.
  final DateTime memberSince;

  /// Nivel de reputación ('high'|'medium'|'low'). Null si el API no lo envía
  /// (compatibilidad con versiones anteriores del backend).
  final String? tier;

  /// Puntos que faltan para subir de nivel. Null si no aplica o no viene.
  final int? pointsToNext;
}

/// Preferencias operativas del ciudadano (GET|PATCH /me/preferences).
class UserPreferencesEntity {
  const UserPreferencesEntity({
    required this.alertRadiusMeters,
    required this.muteNotifications,
    required this.panicRecordAudio,
    required this.panicAlarmSound,
  });

  /// Radio de alertas push en metros (500 – 10000).
  final int alertRadiusMeters;

  /// Si es true, no se reciben push notifications de incidentes.
  final bool muteNotifications;

  /// Si es true, durante el pánico se graba audio cifrado.
  final bool panicRecordAudio;

  /// Si es true, durante el pánico suena la alarma audible del dispositivo.
  final bool panicAlarmSound;

  UserPreferencesEntity copyWith({
    int? alertRadiusMeters,
    bool? muteNotifications,
    bool? panicRecordAudio,
    bool? panicAlarmSound,
  }) =>
      UserPreferencesEntity(
        alertRadiusMeters: alertRadiusMeters ?? this.alertRadiusMeters,
        muteNotifications: muteNotifications ?? this.muteNotifications,
        panicRecordAudio: panicRecordAudio ?? this.panicRecordAudio,
        panicAlarmSound: panicAlarmSound ?? this.panicAlarmSound,
      );
}
