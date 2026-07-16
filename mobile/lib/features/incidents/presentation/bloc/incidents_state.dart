part of 'incidents_bloc.dart';

abstract class IncidentsState {
  const IncidentsState();
}

class IncidentsInitial extends IncidentsState {
  const IncidentsInitial();
}

class IncidentsLoading extends IncidentsState {
  const IncidentsLoading();
}

class IncidentsLoaded extends IncidentsState {
  const IncidentsLoaded({
    required this.incidents,
    this.selectedDetail,
    this.detailLoading = false,
    this.detailWithinVoteRange = false,
    this.pendingConfirmRequest,
  });

  final List<IncidentEntity> incidents;
  final IncidentDetailEntity? selectedDetail;
  final bool detailLoading;

  /// Si el usuario está dentro del radio de voto del incidente abierto en el
  /// detalle. Gatea la CTA "¿Sigue ocurriendo?" — votar de lejos no tiene
  /// sentido y el backend igual lo rechaza (403).
  final bool detailWithinVoteRange;
  final ConfirmRequestEvent? pendingConfirmRequest;

  IncidentsLoaded copyWith({
    List<IncidentEntity>? incidents,
    IncidentDetailEntity? selectedDetail,
    bool? detailLoading,
    bool? detailWithinVoteRange,
    ConfirmRequestEvent? pendingConfirmRequest,
    bool clearDetail = false,
    bool clearConfirmRequest = false,
  }) =>
      IncidentsLoaded(
        incidents: incidents ?? this.incidents,
        selectedDetail:
            clearDetail ? null : (selectedDetail ?? this.selectedDetail),
        detailLoading: detailLoading ?? this.detailLoading,
        detailWithinVoteRange:
            clearDetail ? false : (detailWithinVoteRange ?? this.detailWithinVoteRange),
        pendingConfirmRequest: clearConfirmRequest
            ? null
            : (pendingConfirmRequest ?? this.pendingConfirmRequest),
      );
}

class IncidentsFailure extends IncidentsState {
  const IncidentsFailure(this.message);
  final String message;
}
