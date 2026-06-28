import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsInitial()) {
    on<LoadSettingsRequested>(_onLoad);
    on<ToggleDarkModeRequested>(_onToggleDarkMode);
    on<ToggleNotificationsRequested>(_onToggleNotifications);
    on<ToggleBiometricsRequested>(_onToggleBiometrics);
  }

  void _onLoad(LoadSettingsRequested event, Emitter<SettingsState> emit) {
    emit(const SettingsLoaded(
      isDarkMode: false,
      isNotificationsEnabled: true,
      isBiometricsEnabled: true,
    ));
  }

  void _onToggleDarkMode(ToggleDarkModeRequested event, Emitter<SettingsState> emit) {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(currentState.copyWith(isDarkMode: !currentState.isDarkMode));
    }
  }

  void _onToggleNotifications(ToggleNotificationsRequested event, Emitter<SettingsState> emit) {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(currentState.copyWith(isNotificationsEnabled: !currentState.isNotificationsEnabled));
    }
  }

  void _onToggleBiometrics(ToggleBiometricsRequested event, Emitter<SettingsState> emit) {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(currentState.copyWith(isBiometricsEnabled: !currentState.isBiometricsEnabled));
    }
  }
}
