import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/features/incidents/data/models/incident_model.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';

class ConfirmRequestEvent {
  const ConfirmRequestEvent({
    required this.zoneLabel,
    required this.type,
    this.approxLat,
    this.approxLng,
    this.reportedAt,
  });
  final String zoneLabel;
  final IncidentType type;
  // Coords aproximadas (±100m) para reverse-geocode mobile-side. Nullable por
  // compat con API antiguo o casos donde no se manda.
  final double? approxLat;
  final double? approxLng;
  final DateTime? reportedAt;
}

@lazySingleton
class SocketClient {
  final _incidentNewCtrl = StreamController<IncidentEntity>.broadcast();
  final _incidentUpdatedCtrl = StreamController<IncidentEntity>.broadcast();
  final _confirmRequestCtrl = StreamController<ConfirmRequestEvent>.broadcast();
  final _reportStatusCtrl =
      StreamController<ReportStatusChangedEvent>.broadcast();

  io.Socket? _socket;

  Stream<IncidentEntity> get onIncidentNew => _incidentNewCtrl.stream;
  Stream<IncidentEntity> get onIncidentUpdated => _incidentUpdatedCtrl.stream;
  Stream<ConfirmRequestEvent> get onConfirmRequest => _confirmRequestCtrl.stream;
  Stream<ReportStatusChangedEvent> get onReportStatusChanged =>
      _reportStatusCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({required double lat, required double lng}) async {
    // Guard reforzada: si ya existe socket (conectado O conectándose), no creamos otro.
    // Antes solo chequeábamos `connected == true` → si conectaba dos veces durante el
    // handshake, el primer socket moría con "transport close" en el server.
    if (_socket != null) {
      if (_socket!.connected) {
        debugPrint('[Socket] ya conectado — skip');
        return;
      }
      // Socket existe pero está en limbo (conectando o muerto). Limpiamos.
      debugPrint('[Socket] existente no conectado — disposing antes de recrear');
      _socket!.dispose();
      _socket = null;
    }

    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;

    debugPrint('[Socket] connecting to ${AppConstants.apiBaseUrl} lat=$lat lng=$lng token=${token != null}');

    _socket = io.io(
      AppConstants.apiBaseUrl,
      io.OptionBuilder()
          // Fallback a polling si WS falla — Android suele cortar WebSocket en background
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .disableAutoConnect()
          .setAuth(<String, dynamic>{
            if (token != null) 'token': token,
            'lat': lat,
            'lng': lng,
          })
          .build(),
    )
      ..onConnect((_) => debugPrint('[Socket] ✓ connected id=${_socket?.id}'))
      ..onDisconnect((reason) => debugPrint('[Socket] ✗ disconnect reason=$reason'))
      ..onConnectError((e) => debugPrint('[Socket] ⚠ connect_error $e'))
      ..onError((e) => debugPrint('[Socket] ⚠ error $e'))
      ..onReconnect((_) => debugPrint('[Socket] ↻ reconnected'))
      ..onReconnectAttempt((n) => debugPrint('[Socket] ↻ reconnect attempt $n'))
      ..on('incident:new', _onIncidentNew)
      ..on('incident:updated', _onIncidentUpdated)
      ..on('alert:confirm-request', _onConfirmRequest)
      ..on('report:status-changed', _onReportStatusChanged)
      ..connect();
  }

  void updateLocation(double lat, double lng) {
    _socket?.emit('room:update', <String, dynamic>{'lat': lat, 'lng': lng});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void _onIncidentNew(dynamic data) {
    try {
      _incidentNewCtrl.add(
        IncidentModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (_) {}
  }

  void _onIncidentUpdated(dynamic data) {
    try {
      _incidentUpdatedCtrl.add(
        IncidentModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (_) {}
  }

  void _onConfirmRequest(dynamic data) {
    debugPrint('[Socket] 📨 alert:confirm-request raw=$data');
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final reportedAtStr = map['reportedAt'] as String?;
      final ev = ConfirmRequestEvent(
        zoneLabel: map['zoneLabel'] as String,
        type: IncidentType.fromValue(map['type'] as String),
        approxLat: (map['approxLat'] as num?)?.toDouble(),
        approxLng: (map['approxLng'] as num?)?.toDouble(),
        reportedAt: reportedAtStr != null ? DateTime.tryParse(reportedAtStr) : null,
      );
      debugPrint('[Socket] 📨 parseado OK → push al stream zone=${ev.zoneLabel} type=${ev.type}');
      _confirmRequestCtrl.add(ev);
    } catch (e, st) {
      // Antes: catch(_) silencioso → escondía errores de parse
      debugPrint('[Socket] ⚠ confirm-request PARSE FAILED: $e\n$st');
    }
  }

  void _onReportStatusChanged(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      _reportStatusCtrl.add(ReportStatusChangedEvent(
        incidentId: map['incidentId'] as String,
        status: IncidentStatus.fromValue(map['status'] as String),
        district: map['district'] as String,
        type: IncidentType.fromValue(map['type'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        feedback: map['feedback'] as String?,
      ));
    } catch (_) {}
  }

  @disposeMethod
  void dispose() {
    disconnect();
    _incidentNewCtrl.close();
    _incidentUpdatedCtrl.close();
    _confirmRequestCtrl.close();
    _reportStatusCtrl.close();
  }
}
