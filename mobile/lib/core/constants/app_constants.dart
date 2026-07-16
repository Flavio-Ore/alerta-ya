import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Constantes del sistema AlertaYa
class AppConstants {
  AppConstants._();

  // Rate limiting
  static const int maxReportsPerHour = 3;
  static const int pushCooldownSeconds = 180;

  // Threshold engine — tiempos en minutos
  static const int thresholdWindowMinutes = 15;
  static const int criticalWindowMinutes = 20;
  static const int reportExpiryMinutes = 30;
  static const int confirmationExtensionMinutes = 30;

  // Threshold engine — conteos
  static const int thresholdLow = 2;
  static const int thresholdModerate = 3;
  static const int thresholdCritical = 5;
  static const int massEventCount = 50;
  static const int massEventWindowMinutes = 5;
  static const int forceCriticalFormCount = 3;

  // Pánico — audio
  static const int panicMaxRecordingMinutes = 60;
  static const int panicBlockMinutes = 10;
  static const int panicPinMaxAttempts = 3;
  // Espera tras bloquear el PIN antes de permitir reintentar. Frena fuerza bruta.
  static const int panicPinRetryCooldownSeconds = 30;

  // Geofencing — Lima Metropolitana
  static const double limaLatMin = -12.28;
  static const double limaLatMax = -11.77;
  static const double limaLngMin = -77.17;
  static const double limaLngMax = -76.78;

  // Notificaciones push — radio en metros
  static const double alertRadiusMeters = 2000;

  // UI
  static const double bottomNavHeight = 64;
  static const double panicButtonDiameter = 44;
  static const double panicScreenButtonDiameter = 180;
  static const double fabSize = 56;

  // Red — se lee en runtime desde .env (flutter_dotenv).
  // Fallback apunta a producción (Cloud Run): si el .env no carga, la app
  // release debe seguir funcionando en vez de intentar un host de dev.
  // Para desarrollo local, sobreescribir API_BASE_URL/WS_URL en mobile/.env.
  static const String _prodApiUrl =
      'https://alertaya-api-562740646244.us-central1.run.app';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? _prodApiUrl;
  static String get wsUrl => dotenv.env['WS_URL'] ?? _prodApiUrl;

  // Google Sign-In — Web Client ID (client_type 3 en google-services.json).
  // Requerido por google_sign_in_android v6+ (Credential Manager API).
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  // App
  static const String appName = 'AlertaYa';
  static const String supportEmail = 'soporte@alertaya.pe';
}
