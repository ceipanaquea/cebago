import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileInitial()) {
    on<LoadProfileRequested>(_onLoadProfile);
    on<UpdateDetailsRequested>(_onUpdateDetails);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onLoadProfile(
    LoadProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const ProfileError('Usuario no autenticado'));
        return;
      }

      final perfil = await _supabase
          .from('perfiles')
          .select('nombres, apellidos, email, telefono, rol, codigo_estudiante, promedio_general, asistencia')
          .eq('id', userId)
          .maybeSingle();

      if (perfil == null) {
        emit(const ProfileError('No se encontró el perfil'));
        return;
      }

      final nombres = perfil['nombres'] as String? ?? '';
      final apellidos = perfil['apellidos'] as String? ?? '';
      final rol = perfil['rol'] as String? ?? 'estudiante';
      final isAdmin = rol == 'administrador' || rol == 'director';

      // Obtener la matrícula activa para el ciclo actual
      final matriculas = await _supabase
          .from('matriculas')
          .select('ciclo')
          .eq('perfil_id', userId)
          .order('fecha_creacion', ascending: false)
          .limit(1);

      final currentCycle = matriculas.isNotEmpty
          ? (matriculas.first['ciclo'] as String? ?? 'Sin ciclo inscrito')
          : 'Sin ciclo inscrito';

      final promedio = (perfil['promedio_general'] as num?)?.toDouble() ?? 0.0;
      final asistencia = (perfil['asistencia'] as num?)?.toDouble() ?? 0.0;

      emit(ProfileLoaded(
        studentId: perfil['codigo_estudiante'] as String? ?? 'CEBA-2026-0000',
        fullName: '$nombres $apellidos'.trim(),
        email: perfil['email'] as String? ?? _supabase.auth.currentUser?.email ?? '',
        phone: perfil['telefono'] as String? ?? '',
        address: '', // No hay campo address en el schema
        currentCycle: currentCycle,
        isAdmin: isAdmin,
        attendanceRate: '${asistencia.toStringAsFixed(1)}%',
        academicAverages: '${promedio.toStringAsFixed(1)} / 20',
      ));
    } catch (e) {
      emit(ProfileError('Error al cargar perfil: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDetails(
    UpdateDetailsRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(const ProfileLoading());
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) {
          emit(const ProfileError('Usuario no autenticado'));
          return;
        }

        await _supabase.from('perfiles').update({
          'telefono': event.phone,
          'email': event.email,
        }).eq('id', userId);

        emit(currentState.copyWith(
          email: event.email,
          phone: event.phone,
          address: event.address,
        ));
      } catch (e) {
        emit(ProfileError('Error al actualizar perfil: ${e.toString()}'));
      }
    }
  }
}
