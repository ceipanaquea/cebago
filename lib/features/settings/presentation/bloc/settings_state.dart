import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final bool isDarkMode;
  final bool isNotificationsEnabled;
  final bool isBiometricsEnabled;

  const SettingsLoaded({
    required this.isDarkMode,
    required this.isNotificationsEnabled,
    required this.isBiometricsEnabled,
  });

  SettingsLoaded copyWith({
    bool? isDarkMode,
    bool? isNotificationsEnabled,
    bool? isBiometricsEnabled,
  }) {
    return SettingsLoaded(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
    );
  }

  @override
  List<Object?> get props => [isDarkMode, isNotificationsEnabled, isBiometricsEnabled];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
