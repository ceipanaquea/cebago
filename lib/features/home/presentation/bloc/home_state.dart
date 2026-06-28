import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.userName,
    required this.enrollmentStatus,
    required this.pendingDocuments,
    required this.unreadNotifications,
    required this.nextSteps,
    required this.announcements,
  });

  final String userName;
  final String enrollmentStatus;
  final int pendingDocuments;
  final int unreadNotifications;
  final List<HomeStep> nextSteps;
  final List<HomeAnnouncement> announcements;

  @override
  List<Object?> get props => [
        userName,
        enrollmentStatus,
        pendingDocuments,
        unreadNotifications,
        nextSteps,
        announcements,
      ];
}

class HomeError extends HomeState {
  const HomeError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}

// ----- Sub-modelos -----
class HomeStep extends Equatable {
  const HomeStep({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.icon,
  });
  final String title;
  final String description;
  final bool isCompleted;
  final String icon;
  @override
  List<Object?> get props => [title, isCompleted];
}

class HomeAnnouncement extends Equatable {
  const HomeAnnouncement({
    required this.title,
    required this.body,
    required this.date,
    required this.isNew,
  });
  final String title;
  final String body;
  final DateTime date;
  final bool isNew;
  @override
  List<Object?> get props => [title, date];
}
