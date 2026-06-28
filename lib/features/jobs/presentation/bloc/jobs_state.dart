import 'package:equatable/equatable.dart';

class JobModel extends Equatable {
  final String id;
  final String title;
  final String location;
  final String mode; // Presencial, Semi-presencial, Distancia
  final String schedule; // Turno Noche, Turno Tarde, Fin de semana
  final String level; // Ciclo Inicial / Intermedio, Ciclo Avanzado
  final int totalVacancies;
  final int availableVacancies;
  final String description;
  final List<String> requirements;
  final String contactEmail;

  const JobModel({
    required this.id,
    required this.title,
    required this.location,
    required this.mode,
    required this.schedule,
    required this.level,
    required this.totalVacancies,
    required this.availableVacancies,
    required this.description,
    required this.requirements,
    required this.contactEmail,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        location,
        mode,
        schedule,
        level,
        totalVacancies,
        availableVacancies,
        description,
        requirements,
        contactEmail,
      ];
}

abstract class JobsState extends Equatable {
  const JobsState();

  @override
  List<Object?> get props => [];
}

class JobsInitial extends JobsState {
  const JobsInitial();
}

class JobsLoading extends JobsState {
  const JobsLoading();
}

class JobsLoaded extends JobsState {
  final List<JobModel> allJobs;
  final List<JobModel> filteredJobs;
  final String query;
  final String selectedCategory;

  const JobsLoaded({
    required this.allJobs,
    required this.filteredJobs,
    this.query = '',
    this.selectedCategory = 'Todos',
  });

  JobsLoaded copyWith({
    List<JobModel>? allJobs,
    List<JobModel>? filteredJobs,
    String? query,
    String? selectedCategory,
  }) {
    return JobsLoaded(
      allJobs: allJobs ?? this.allJobs,
      filteredJobs: filteredJobs ?? this.filteredJobs,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [allJobs, filteredJobs, query, selectedCategory];
}

class JobsError extends JobsState {
  final String message;

  const JobsError(this.message);

  @override
  List<Object?> get props => [message];
}
