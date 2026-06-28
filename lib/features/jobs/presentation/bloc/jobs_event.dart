import 'package:equatable/equatable.dart';

abstract class JobsEvent extends Equatable {
  const JobsEvent();

  @override
  List<Object?> get props => [];
}

class LoadJobsRequested extends JobsEvent {
  const LoadJobsRequested();
}

class FilterJobsRequested extends JobsEvent {
  final String query;
  final String category;

  const FilterJobsRequested({
    this.query = '',
    this.category = 'Todos',
  });

  @override
  List<Object?> get props => [query, category];
}
