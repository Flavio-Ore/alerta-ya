part of 'alerts_bloc.dart';

abstract class AlertsEvent {
  const AlertsEvent();
}

class AlertsLoaded extends AlertsEvent {
  const AlertsLoaded();
}

class AlertsRefreshed extends AlertsEvent {
  const AlertsRefreshed();
}

class AlertsNotificationTapped extends AlertsEvent {
  const AlertsNotificationTapped(this.id);
  final String id;
}

class AlertsMarkAllRead extends AlertsEvent {
  const AlertsMarkAllRead();
}
