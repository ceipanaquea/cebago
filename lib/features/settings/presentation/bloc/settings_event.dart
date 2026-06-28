import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsRequested extends SettingsEvent {
  const LoadSettingsRequested();
}

class ToggleDarkModeRequested extends SettingsEvent {
  const ToggleDarkModeRequested();
}

class ToggleNotificationsRequested extends SettingsEvent {
  const ToggleNotificationsRequested();
}

class ToggleBiometricsRequested extends SettingsEvent {
  const ToggleBiometricsRequested();
}
