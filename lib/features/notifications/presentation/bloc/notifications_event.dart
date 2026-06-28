import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsRequested extends NotificationsEvent {
  const LoadNotificationsRequested();
}

class MarkAsReadRequested extends NotificationsEvent {
  final String id;
  const MarkAsReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearAllRequested extends NotificationsEvent {
  const ClearAllRequested();
}
