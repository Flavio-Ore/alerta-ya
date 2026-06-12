import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Evento de notificación push que el resto de la app puede consumir
/// (e.g. para navegar al detalle del incidente al tocar la notif).
class FcmIncidentNotification {
  const FcmIncidentNotification({
    required this.incidentId,
    required this.title,
    required this.body,
  });
  final String incidentId;
  final String title;
  final String body;
}

/// Notificación de confirm-request — primer reporte sin incidente publicado.
/// Lleva coords aproximadas para que el mobile reverse-geocode y muestre el sheet.
class FcmConfirmRequestNotification {
  const FcmConfirmRequestNotification({
    required this.zoneLabel,
    required this.incidentType,
    required this.approxLat,
    required this.approxLng,
    required this.reportedAt,
  });
  final String zoneLabel;
  final String incidentType;
  final double approxLat;
  final double approxLng;
  final DateTime reportedAt;
}

/// Registra el device token FCM en el API después del login.
/// Sin token registrado, el backend no puede mandar push notifications.
@lazySingleton
class FcmService {
  FcmService(this._dio);
  final Dio _dio;

  // Streams para que el resto de la app consuma — foreground = mostrar snackbar,
  // openedFromBackground = navegar al detalle del incidente.
  final _foregroundCtrl = StreamController<FcmIncidentNotification>.broadcast();
  final _openedCtrl = StreamController<FcmIncidentNotification>.broadcast();
  // Confirm-request: stream separado porque la acción es distinta (abrir sheet,
  // no navegar a detalle). Emite tanto en foreground como al abrir desde tap.
  final _confirmRequestCtrl =
      StreamController<FcmConfirmRequestNotification>.broadcast();

  Stream<FcmIncidentNotification> get onForegroundMessage => _foregroundCtrl.stream;
  Stream<FcmIncidentNotification> get onNotificationOpened => _openedCtrl.stream;
  Stream<FcmConfirmRequestNotification> get onConfirmRequest =>
      _confirmRequestCtrl.stream;

  bool _handlersWired = false;

  /// Obtener token y registrarlo en el API.
  /// Solo procede si el permiso de notificaciones ya fue concedido por el usuario.
  /// El permiso se solicita durante el onboarding — nunca aquí.
  /// Silencia errores — una falla aquí NO debe bloquear el login.
  /// [lat]/[lng] opcionales — si se mandan, el server calcula proxTile (~330m).
  Future<void> registerToken({double? lat, double? lng}) async {
    try {
      // Verificar sin solicitar — el onboarding es el único lugar donde se pide.
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await _dio.post<void>(
        '/auth/device-token',
        data: {
          'token': token,
          // MVP: toda la app está limitada a Lima — el distrito se refina
          // con GPS cuando se implemente geofencing real (HU007).
          'district': 'Lima',
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );

      // Escuchar refresh de token (Android lo rota periódicamente)
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      // Handlers de mensajes — solo una vez por proceso.
      _wireMessageHandlers();
    } catch (e) {
      debugPrint('[FCM] ⚠ registerToken falló: $e');
    }
  }

  /// Actualiza solo la ubicación del device_token (cuando el GPS del user cambia).
  /// No re-pide token ni permisos — más liviano que registerToken().
  Future<void> updateLocation({required double lat, required double lng}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _dio.post<void>(
        '/auth/device-token',
        data: {
          'token': token,
          'district': 'Lima',
          'lat': lat,
          'lng': lng,
        },
      );
    } catch (e) {
      debugPrint('[FCM] ⚠ updateLocation falló: $e');
    }
  }

  /// Conecta los listeners de mensajes FCM. Idempotente.
  void _wireMessageHandlers() {
    if (_handlersWired) return;
    _handlersWired = true;

    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM] foreground msg=${msg.notification?.title} data=${msg.data}');
      _dispatch(msg, openedFromBackground: false);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('[FCM] opened from background msg=${msg.notification?.title}');
      _dispatch(msg, openedFromBackground: true);
    });

    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg == null) return;
      debugPrint('[FCM] cold start desde notif msg=${msg.notification?.title}');
      _dispatch(msg, openedFromBackground: true);
    });
  }

  // Discrimina por data.type y empuja al stream correspondiente.
  // 'confirm-request' → onConfirmRequest. Cualquier otro con incidentId → incidente.
  void _dispatch(RemoteMessage msg, {required bool openedFromBackground}) {
    final type = msg.data['type'] as String?;
    if (type == 'confirm-request') {
      final ev = _parseConfirmRequest(msg);
      if (ev != null) _confirmRequestCtrl.add(ev);
      return;
    }
    final ev = _parseIncident(msg);
    if (ev == null) return;
    if (openedFromBackground) {
      _openedCtrl.add(ev);
    } else {
      _foregroundCtrl.add(ev);
    }
  }

  FcmIncidentNotification? _parseIncident(RemoteMessage msg) {
    final id = msg.data['incidentId'] as String?;
    if (id == null) return null;
    return FcmIncidentNotification(
      incidentId: id,
      title: msg.notification?.title ?? 'AlertaYa',
      body: msg.notification?.body ?? '',
    );
  }

  FcmConfirmRequestNotification? _parseConfirmRequest(RemoteMessage msg) {
    final zone = msg.data['zoneLabel'] as String?;
    final type = msg.data['incidentType'] as String?;
    final lat = double.tryParse(msg.data['approxLat']?.toString() ?? '');
    final lng = double.tryParse(msg.data['approxLng']?.toString() ?? '');
    final reportedAtStr = msg.data['reportedAt'] as String?;
    if (zone == null || type == null || lat == null || lng == null) return null;
    return FcmConfirmRequestNotification(
      zoneLabel: zone,
      incidentType: type,
      approxLat: lat,
      approxLng: lng,
      reportedAt: reportedAtStr != null
          ? (DateTime.tryParse(reportedAtStr) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Eliminar token al cerrar sesión para no recibir pushes de otra cuenta.
  Future<void> unregisterToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _dio.delete<void>('/auth/device-token', data: {'token': token});
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> _onTokenRefresh(String newToken) async {
    try {
      await _dio.post<void>(
        '/auth/device-token',
        data: {'token': newToken, 'district': 'Lima'},
      );
    } catch (_) {}
  }
}
