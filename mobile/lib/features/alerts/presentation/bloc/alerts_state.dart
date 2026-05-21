part of 'alerts_bloc.dart';

abstract class AlertsState {
  const AlertsState();
}

class AlertsInitial extends AlertsState {
  const AlertsInitial();
}

class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

class AlertsData extends AlertsState {
  const AlertsData({required this.notifications});
  final List<NotificationEntity> notifications;

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class AlertsFailure extends AlertsState {
  const AlertsFailure(this.message);
  final String message;
}
