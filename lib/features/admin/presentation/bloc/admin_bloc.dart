import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc() : super(const AdminInitial()) {
    on<LoadAdminDataRequested>(_onLoadAdminData);
    on<ApproveEnrollmentRequested>(_onApproveEnrollment);
    on<RejectEnrollmentRequested>(_onRejectEnrollment);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onLoadAdminData(
    LoadAdminDataRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      // Administradores ven TODAS las matrículas (gracias a la política RLS de admin)
      final result = await _supabase
          .from('matriculas')
          .select('''
            id,
            codigo_ticket,
            nombres,
            apellidos,
            dni,
            ciclo,
            estado,
            fecha_creacion,
            perfil_id
          ''')
          .order('fecha_creacion', ascending: false);

      final requests = result.map<AdminEnrollmentRequest>((mat) {
        final fecha = DateTime.tryParse(mat['fecha_creacion'] as String? ?? '');
        final fechaStr = fecha != null
            ? '${fecha.day} ${_monthName(fecha.month)}, ${fecha.year}'
            : 'Fecha desconocida';

        final nombres = mat['nombres'] as String? ?? '';
        final apellidos = mat['apellidos'] as String? ?? '';

        return AdminEnrollmentRequest(
          id: mat['codigo_ticket'] as String? ?? mat['id'] as String,
          studentName: '$nombres $apellidos'.trim(),
          cycle: mat['ciclo'] as String? ?? 'Sin ciclo',
          date: fechaStr,
          status: mat['estado'] as String? ?? 'Pendiente',
          dni: mat['dni'] as String? ?? '',
          perfilId: mat['perfil_id'] as String? ?? '',
          matriculaId: mat['id'] as String,
        );
      }).toList();

      _emitLoadedState(emit, requests);
    } catch (e) {
      emit(AdminError('Error al cargar solicitudes: ${e.toString()}'));
    }
  }

  Future<void> _onApproveEnrollment(
    ApproveEnrollmentRequested event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminLoaded) {
      try {
        // Encontrar la matrícula con ese código/id
        final request = currentState.requests.firstWhere(
          (r) => r.id == event.id,
          orElse: () => currentState.requests.first,
        );

        // Actualizar en Supabase usando el matriculaId real
        await _supabase
            .from('matriculas')
            .update({'estado': 'Aprobado'})
            .eq('id', request.matriculaId.isNotEmpty ? request.matriculaId : event.id);

        // Notificar al estudiante
        if (request.perfilId.isNotEmpty) {
          await _supabase.from('notificaciones').insert({
            'perfil_id': request.perfilId,
            'titulo': '¡Matrícula Aprobada! 🎉',
            'mensaje':
                'Tu solicitud de matrícula ${request.id} ha sido aprobada. ¡Bienvenido al CEBA Go!',
            'categoria': 'Matrícula',
            'leido': false,
          });
        }

        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Aprobado');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList);
      } catch (e) {
        // Actualizar localmente si falla la BD
        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Aprobado');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList);
      }
    }
  }

  Future<void> _onRejectEnrollment(
    RejectEnrollmentRequested event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminLoaded) {
      try {
        final request = currentState.requests.firstWhere(
          (r) => r.id == event.id,
          orElse: () => currentState.requests.first,
        );

        await _supabase
            .from('matriculas')
            .update({
              'estado': 'Observado',
              'observaciones': event.observaciones ?? 'Se requieren correcciones en los documentos.',
            })
            .eq('id', request.matriculaId.isNotEmpty ? request.matriculaId : event.id);

        // Notificar al estudiante
        if (request.perfilId.isNotEmpty) {
          await _supabase.from('notificaciones').insert({
            'perfil_id': request.perfilId,
            'titulo': 'Matrícula Observada',
            'mensaje':
                'Tu solicitud ${request.id} necesita correcciones: ${event.observaciones ?? 'Revisa los documentos requeridos.'}',
            'categoria': 'Matrícula',
            'leido': false,
          });
        }

        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Observado');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList);
      } catch (e) {
        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Observado');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList);
      }
    }
  }

  void _emitLoadedState(Emitter<AdminState> emit, List<AdminEnrollmentRequest> list) {
    final total = list.length;
    final approved = list.where((r) => r.status == 'Aprobado').length;
    final pending = list.where((r) => r.status == 'Pendiente').length;
    final observed = list.where((r) => r.status == 'Observado').length;

    emit(AdminLoaded(
      stats: AdminStats(
        totalRequests: total,
        approvedCount: approved,
        pendingCount: pending,
        observedCount: observed,
      ),
      requests: list,
    ));
  }

  String _monthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }
}
