import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}
