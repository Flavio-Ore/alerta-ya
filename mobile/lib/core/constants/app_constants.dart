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

  // Pánico
  static const int panicMaxRecordingMinutes = 60;
  static const int panicBlockMinutes = 10;
  static const int panicPinMaxAttempts = 3;

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

  // App
  static const String appName = 'AlertaYa';
  static const String supportEmail = 'soporte@alertaya.pe';
}
