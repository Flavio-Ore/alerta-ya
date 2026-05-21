import 'dart:async';

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

  Future<void> _onStarted(
      IncidentsStarted event, Emitter<IncidentsState> emit) async {
    emit(const IncidentsLoading());
    final result = await _getIncidents(const GetIncidentsParams());
    result.fold(
      (f) => emit(IncidentsFailure(f.toString())),
      (incidents) => emit(IncidentsLoaded(incidents: incidents)),
    );
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
    emit(current.copyWith(detailLoading: true));
    final result = await _getDetail(event.id);
    result.fold(
      (_) => emit(current.copyWith(detailLoading: false)),
      (detail) =>
          emit(current.copyWith(selectedDetail: detail, detailLoading: false)),
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
    if (state is IncidentsLoaded) {
      emit((state as IncidentsLoaded)
          .copyWith(pendingConfirmRequest: event.event));
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
