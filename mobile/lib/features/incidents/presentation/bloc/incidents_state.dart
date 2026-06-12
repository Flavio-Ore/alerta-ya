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
    this.pendingConfirmRequest,
  });

  final List<IncidentEntity> incidents;
  final IncidentDetailEntity? selectedDetail;
  final bool detailLoading;
  final ConfirmRequestEvent? pendingConfirmRequest;

  IncidentsLoaded copyWith({
    List<IncidentEntity>? incidents,
    IncidentDetailEntity? selectedDetail,
    bool? detailLoading,
    ConfirmRequestEvent? pendingConfirmRequest,
    bool clearDetail = false,
    bool clearConfirmRequest = false,
  }) =>
      IncidentsLoaded(
        incidents: incidents ?? this.incidents,
        selectedDetail:
            clearDetail ? null : (selectedDetail ?? this.selectedDetail),
        detailLoading: detailLoading ?? this.detailLoading,
        pendingConfirmRequest: clearConfirmRequest
            ? null
            : (pendingConfirmRequest ?? this.pendingConfirmRequest),
      );
}

class IncidentsFailure extends IncidentsState {
  const IncidentsFailure(this.message);
  final String message;
}
