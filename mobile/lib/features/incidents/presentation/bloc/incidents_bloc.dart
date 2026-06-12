import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/realtime/socket_client.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/domain/usecases/confirm_incident_usecase.dart';
import 'package:alertaya/features/incidents/domain/usecases/confirm_zone_usecase.dart';
import 'package:alertaya/features/incidents/domain/usecases/get_incident_detail_usecase.dart';
import 'package:alertaya/features/incidents/domain/usecases/get_incidents_usecase.dart';

part 'incidents_event.dart';
part 'incidents_state.dart';

@lazySingleton
class IncidentsBloc extends Bloc<IncidentsEvent, IncidentsState> {
  IncidentsBloc(
    this._getIncidents,
    this._getDetail,
    this._confirmIncident,
    this._confirmZone,
    this._socketClient,
  ) : super(const IncidentsInitial()) {
    on<IncidentsStarted>(_onStarted);
    on<IncidentNewReceived>(_onNewReceived);
    on<IncidentUpdatedReceived>(_onUpdatedReceived);
    on<IncidentDetailRequested>(_onDetailRequested);
    on<IncidentConfirmSubmitted>(_onConfirmSubmitted);
    on<ZoneConfirmSubmitted>(_onZoneConfirmSubmitted);
    on<ConfirmRequestReceived>(_onConfirmRequestReceived);
    on<ConfirmRequestDismissed>(_onConfirmRequestDismissed);

    _newSub = _socketClient.onIncidentNew
        .listen((i) => add(IncidentNewReceived(i)));
    _updatedSub = _socketClient.onIncidentUpdated
        .listen((i) => add(IncidentUpdatedReceived(i)));
    _confirmSub = _socketClient.onConfirmRequest
        .listen((e) => add(ConfirmRequestReceived(e)));
  }

  final GetIncidentsUseCase _getIncidents;
  final GetIncidentDetailUseCase _getDetail;
  final ConfirmIncidentUseCase _confirmIncident;
  final ConfirmZoneUseCase _confirmZone;
  final SocketClient _socketClient;

  late final StreamSubscription<IncidentEntity> _newSub;
  late final StreamSubscription<IncidentEntity> _updatedSub;
  late final StreamSubscription<ConfirmRequestEvent> _confirmSub;

  // Buffer para confirm-request que llega antes de que se carguen los incidentes.
  // Si el WS dispara durante IncidentsLoading, guardamos el evento aquí y lo
  // aplicamos cuando la transición a IncidentsLoaded termine.
  ConfirmRequestEvent? _bufferedConfirmRequest;

  Future<void> _onStarted(
      IncidentsStarted event, Emitter<IncidentsState> emit) async {
    emit(const IncidentsLoading());

    // Reintento automático: si el primer fetch falla (e.g. token Firebase aún
    // no listo en boot), intentamos hasta 3 veces con backoff antes de Failure.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await _getIncidents(const GetIncidentsParams());
      final succeeded = result.fold(
        (f) {
          debugPrint('[IncidentsBloc] ⚠ GET /incidents intento $attempt/$maxAttempts falló: $f');
          return false;
        },
        (incidents) {
          final pending = _bufferedConfirmRequest;
          _bufferedConfirmRequest = null;
          emit(IncidentsLoaded(
            incidents: incidents,
            pendingConfirmRequest: pending,
          ));
          debugPrint('[IncidentsBloc] ✓ ${incidents.length} incidentes cargados en intento $attempt');
          return true;
        },
      );
      if (succeeded) return;
      if (attempt < maxAttempts) {
        await Future<void>.delayed(Duration(seconds: attempt));
      } else {
        // Último intento — emitir el error del último fold
        result.fold(
          (f) => emit(IncidentsFailure(f.toString())),
          (_) {},
        );
      }
    }
  }

  void _onNewReceived(
      IncidentNewReceived event, Emitter<IncidentsState> emit) {
    if (state is! IncidentsLoaded) return;
    final current = state as IncidentsLoaded;
    emit(current.copyWith(incidents: [event.incident, ...current.incidents]));
  }

  void _onUpdatedReceived(
      IncidentUpdatedReceived event, Emitter<IncidentsState> emit) {
    if (state is! IncidentsLoaded) return;
    final current = state as IncidentsLoaded;
    final updated = current.incidents
        .map((i) => i.id == event.incident.id ? event.incident : i)
        .toList();
    emit(current.copyWith(incidents: updated));
  }

  Future<void> _onDetailRequested(
      IncidentDetailRequested event, Emitter<IncidentsState> emit) async {
    if (state is! IncidentsLoaded) return;
    final current = state as IncidentsLoaded;
    debugPrint('[IncidentsBloc] 🔎 IncidentDetailRequested id=${event.id}');
    // Limpiar el detalle anterior antes de pedir el nuevo — evita que el sheet
    // muestre data stale del marker anterior mientras carga el nuevo.
    emit(current.copyWith(clearDetail: true, detailLoading: true));
    final result = await _getDetail(event.id);
    result.fold(
      (f) {
        debugPrint('[IncidentsBloc] ⚠ getDetail(${event.id}) FAILED: $f');
        emit(current.copyWith(clearDetail: true, detailLoading: false));
      },
      (detail) {
        debugPrint('[IncidentsBloc] ✓ detail recibido id=${detail.id} type=${detail.type} severity=${detail.severity}');
        emit(current.copyWith(selectedDetail: detail, detailLoading: false));
      },
    );
  }

  Future<void> _onConfirmSubmitted(
      IncidentConfirmSubmitted event, Emitter<IncidentsState> emit) async {
    await _confirmIncident(ConfirmIncidentParams(
      id: event.id,
      vote: event.stillHere ? 'yes' : 'no',
    ));
  }

  Future<void> _onZoneConfirmSubmitted(
      ZoneConfirmSubmitted event, Emitter<IncidentsState> emit) async {
    if (state is IncidentsLoaded) {
      emit((state as IncidentsLoaded).copyWith(clearConfirmRequest: true));
    }
    await _confirmZone(
      ConfirmZoneParams(zoneKey: event.zoneKey, response: event.response),
    );
  }

  void _onConfirmRequestReceived(
      ConfirmRequestReceived event, Emitter<IncidentsState> emit) {
    debugPrint('[IncidentsBloc] 📨 ConfirmRequestReceived state=${state.runtimeType} zone=${event.event.zoneLabel} type=${event.event.type}');
    if (state is IncidentsLoaded) {
      debugPrint('[IncidentsBloc] ✓ emit IncidentsLoaded con pendingConfirmRequest');
      emit((state as IncidentsLoaded)
          .copyWith(pendingConfirmRequest: event.event));
    } else {
      // Bufferear el evento Y disparar retry del fetch — sino el evento queda
      // huérfano cuando la carga inicial falló (estado terminal IncidentsFailure).
      debugPrint('[IncidentsBloc] ⏳ state no es IncidentsLoaded — buffereando + retry fetch');
      _bufferedConfirmRequest = event.event;
      if (state is! IncidentsLoading) {
        add(const IncidentsStarted());
      }
    }
  }

  void _onConfirmRequestDismissed(
      ConfirmRequestDismissed event, Emitter<IncidentsState> emit) {
    if (state is IncidentsLoaded) {
      emit((state as IncidentsLoaded).copyWith(clearConfirmRequest: true));
    }
  }

  @override
  Future<void> close() {
    _newSub.cancel();
    _updatedSub.cancel();
    _confirmSub.cancel();
    return super.close();
  }
}
