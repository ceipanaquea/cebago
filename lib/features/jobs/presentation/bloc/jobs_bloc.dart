import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'jobs_event.dart';
import 'jobs_state.dart';

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  JobsBloc() : super(const JobsInitial()) {
    on<LoadJobsRequested>(_onLoadJobs);
    on<FilterJobsRequested>(_onFilterJobs);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onLoadJobs(LoadJobsRequested event, Emitter<JobsState> emit) async {
    emit(const JobsLoading());
    try {
      final result = await _supabase
          .from('vacantes')
          .select('id, titulo, descripcion, ciclo_escolar, sede, taller_tecnico, modalidad, cupos_totales, cupos_ocupados')
          .order('created_at', ascending: false);

      final jobs = result.map<JobModel>((v) {
        final totalCupos = v['cupos_totales'] as int? ?? 0;
        final ocupados = v['cupos_ocupados'] as int? ?? 0;
        final disponibles = totalCupos - ocupados;
        final modalidad = v['modalidad'] as String? ?? 'Presencial';
        final levelValue = v['ciclo_escolar'] as String? ?? 'Ciclo Avanzado';

        return JobModel(
          id: v['id'] as String,
          title: '${v['taller_tecnico']} - ${v['sede']}',
          location: v['sede'] as String? ?? '',
          mode: modalidad,
          schedule: 'Periodo Académico 2026',
          level: levelValue,
          totalVacancies: totalCupos,
          availableVacancies: disponibles,
          description: v['descripcion'] as String? ?? '',
          requirements: [
            'Copia de DNI vigente.',
            'Foto tamaño carnet a color.',
            'Certificado de estudios previos.',
          ],
          contactEmail: 'matricula@cebago.edu.pe',
        );
      }).toList();

      emit(JobsLoaded(
        allJobs: jobs,
        filteredJobs: jobs,
      ));
    } catch (e) {
      // Si falla Supabase, mostrar mensaje de error
      emit(JobsError('Error al cargar vacantes: ${e.toString()}'));
    }
  }

  void _onFilterJobs(FilterJobsRequested event, Emitter<JobsState> emit) {
    final currentState = state;
    if (currentState is JobsLoaded) {
      final query = event.query.toLowerCase();
      final category = event.category;

      final filtered = currentState.allJobs.where((job) {
        final matchesQuery = job.title.toLowerCase().contains(query) ||
            job.location.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query);

        bool matchesCategory = false;
        if (category == 'Todos') {
          matchesCategory = true;
        } else if (category == 'Ciclo Inicial / Intermedio (Primaria)') {
          matchesCategory = job.level == 'Ciclo Inicial / Intermedio';
        } else if (category == 'Ciclo Avanzado (Secundaria)') {
          matchesCategory = job.level == 'Ciclo Avanzado';
        } else {
          matchesCategory = job.mode == category || job.level == category;
        }

        return matchesQuery && matchesCategory;
      }).toList();

      emit(currentState.copyWith(
        filteredJobs: filtered,
        query: event.query,
        selectedCategory: category,
      ));
    }
  }
}
