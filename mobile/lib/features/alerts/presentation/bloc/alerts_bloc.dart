import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/alerts/domain/entities/notification_entity.dart';
import 'package:alertaya/features/alerts/domain/usecases/get_notifications_usecase.dart';
import 'package:alertaya/features/alerts/domain/usecases/mark_notifications_read_usecase.dart';

part 'alerts_event.dart';
part 'alerts_state.dart';

@injectable
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc(this._getNotifications, this._markRead)
      : super(const AlertsInitial()) {
    on<AlertsLoaded>(_onLoaded);
    on<AlertsRefreshed>(_onRefreshed);
    on<AlertsNotificationTapped>(_onNotificationTapped);
    on<AlertsMarkAllRead>(_onMarkAllRead);
  }

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationsReadUseCase _markRead;

  Future<void> _onLoaded(AlertsLoaded event, Emitter<AlertsState> emit) async {
    emit(const AlertsLoading());
    await _fetchNotifications(emit);
  }

  Future<void> _onRefreshed(
          AlertsRefreshed event, Emitter<AlertsState> emit) =>
      _fetchNotifications(emit);

  Future<void> _fetchNotifications(Emitter<AlertsState> emit) async {
    final result = await _getNotifications(const GetNotificationsParams());
    result.fold(
      (f) => emit(AlertsFailure(f.toString())),
      (notifications) => emit(AlertsData(notifications: notifications)),
    );
  }

  Future<void> _onNotificationTapped(
    AlertsNotificationTapped event,
    Emitter<AlertsState> emit,
  ) async {
    if (state is! AlertsData) return;
    final current = state as AlertsData;
    final notification =
        current.notifications.where((n) => n.id == event.id).firstOrNull;
    if (notification == null || notification.isRead) return;

    // Optimistic update
    final updated = current.notifications
        .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
        .toList();
    emit(AlertsData(notifications: updated));
    await _markRead(MarkReadParams(ids: [event.id]));
  }

  Future<void> _onMarkAllRead(
    AlertsMarkAllRead event,
    Emitter<AlertsState> emit,
  ) async {
    if (state is! AlertsData) return;
    final current = state as AlertsData;
    final updated =
        current.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(AlertsData(notifications: updated));
    await _markRead(const MarkReadParams(all: true));
  }
}
