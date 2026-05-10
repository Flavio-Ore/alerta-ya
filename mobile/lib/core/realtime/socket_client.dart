import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/features/incidents/data/models/incident_model.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';

class ConfirmRequestEvent {
  const ConfirmRequestEvent({required this.zoneLabel, required this.type});
  final String zoneLabel;
  final IncidentType type;
}

@lazySingleton
class SocketClient {
  final _incidentNewCtrl = StreamController<IncidentEntity>.broadcast();
  final _incidentUpdatedCtrl = StreamController<IncidentEntity>.broadcast();
  final _confirmRequestCtrl = StreamController<ConfirmRequestEvent>.broadcast();

  io.Socket? _socket;

  Stream<IncidentEntity> get onIncidentNew => _incidentNewCtrl.stream;
  Stream<IncidentEntity> get onIncidentUpdated => _incidentUpdatedCtrl.stream;
  Stream<ConfirmRequestEvent> get onConfirmRequest => _confirmRequestCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({required double lat, required double lng}) async {
    if (_socket?.connected == true) return;

    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;

    _socket = io.io(
      AppConstants.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(<String, dynamic>{
            if (token != null) 'token': token,
            'lat': lat,
            'lng': lng,
          })
          .build(),
    )
      ..on('incident:new', _onIncidentNew)
      ..on('incident:updated', _onIncidentUpdated)
      ..on('alert:confirm-request', _onConfirmRequest)
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
    try {
      final map = Map<String, dynamic>.from(data as Map);
      _confirmRequestCtrl.add(ConfirmRequestEvent(
        zoneLabel: map['zoneLabel'] as String,
        type: IncidentType.fromValue(map['type'] as String),
      ));
    } catch (_) {}
  }

  @disposeMethod
  void dispose() {
    disconnect();
    _incidentNewCtrl.close();
    _incidentUpdatedCtrl.close();
    _confirmRequestCtrl.close();
  }
}
