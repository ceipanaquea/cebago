import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc() : super(const AdminInitial()) {
    on<LoadAdminDataRequested>(_onLoadAdminData);
    on<ApproveEnrollmentRequested>(_onApproveEnrollment);
    on<RejectEnrollmentRequested>(_onRejectEnrollment);
    on<FilterEnrollmentsRequested>(_onFilterEnrollments);
    on<AddObservationRequested>(_onAddObservation);
    on<MarkUnderReviewRequested>(_onMarkUnderReview);
    on<RejectEnrollmentDirectlyRequested>(_onRejectDirectly);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onLoadAdminData(
    LoadAdminDataRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
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
            perfil_id,
            telefono,
            email_contacto,
            modalidad_estudio,
            observaciones,
            url_dni,
            url_foto,
            url_certificado_primaria,
            url_certificado_secundaria,
            url_doc_discapacidad,
            tiene_discapacidad,
            solicita_prueba_ubicacion
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
          phone: mat['telefono'] as String? ?? '',
          email: mat['email_contacto'] as String? ?? '',
          studyMode: mat['modalidad_estudio'] as String? ?? 'Presencial',
          observations: mat['observaciones'] as String? ?? '',
          urlDni: mat['url_dni'] as String? ?? '',
          urlPhoto: mat['url_foto'] as String? ?? '',
          urlCert: mat['url_certificado_primaria'] as String? ?? mat['url_certificado_secundaria'] as String? ?? '',
          urlDisabilityDoc: mat['url_doc_discapacidad'] as String? ?? '',
          hasDisability: mat['tiene_discapacidad'] as bool? ?? false,
          requestsPlacementTest: mat['solicita_prueba_ubicacion'] as bool? ?? false,
        );
      }).toList();

      _emitLoadedState(emit, requests, '', '');
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
        final request = currentState.requests.firstWhere(
          (r) => r.id == event.id,
          orElse: () => currentState.requests.first,
        );

        await _supabase
            .from('matriculas')
            .update({'estado': 'Aprobado'})
            .eq('id', request.matriculaId.isNotEmpty ? request.matriculaId : event.id);

        if (request.perfilId.isNotEmpty) {
          await _supabase.from('notificaciones').insert({
            'perfil_id': request.perfilId,
            'titulo': '¡Matrícula Aprobada! 🎉',
            'mensaje': 'Tu solicitud de matrícula ${request.id} ha sido aprobada. ¡Bienvenido al CEBA Go!',
            'categoria': 'Matrícula',
            'leido': false,
          });
        }

        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Aprobado');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      } catch (e) {
        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Aprobado');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
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

        if (request.perfilId.isNotEmpty) {
          await _supabase.from('notificaciones').insert({
            'perfil_id': request.perfilId,
            'titulo': 'Matrícula Observada',
            'mensaje': 'Tu solicitud ${request.id} necesita correcciones: ${event.observaciones ?? 'Revisa los documentos requeridos.'}',
            'categoria': 'Matrícula',
            'leido': false,
          });
        }

        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Observado', observations: event.observaciones);
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      } catch (e) {
        final updatedList = currentState.requests.map((req) {
          if (req.id == event.id) return req.copyWith(status: 'Observado', observations: event.observaciones);
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      }
    }
  }

  Future<void> _onFilterEnrollments(
    FilterEnrollmentsRequested event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminLoaded) {
      _emitLoadedState(emit, currentState.requests, event.status, event.mode);
    }
  }

  Future<void> _onAddObservation(
    AddObservationRequested event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminLoaded) {
      try {
        await _supabase.from('matriculas').update({
          'estado': 'Observado',
          'observaciones': event.observationText,
        }).eq('id', event.matriculaId);

        if (event.perfilId.isNotEmpty) {
          await _supabase.from('notificaciones').insert({
            'perfil_id': event.perfilId,
            'titulo': 'Matrícula Observada — Corrección Requerida',
            'mensaje': 'Tu solicitud ${event.ticketCode} necesita correcciones: ${event.observationText}',
            'categoria': 'Matrícula',
            'leido': false,
          });
        }

        final updatedList = currentState.requests.map((req) {
          if (req.matriculaId == event.matriculaId) {
            return req.copyWith(status: 'Observado', observations: event.observationText);
          }
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      } catch (e) {
        final updatedList = currentState.requests.map((req) {
          if (req.matriculaId == event.matriculaId) {
            return req.copyWith(status: 'Observado', observations: event.observationText);
          }
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      }
    }
  }

  Future<void> _onMarkUnderReview(
    MarkUnderReviewRequested event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminLoaded) {
      try {
        await _supabase.from('matriculas').update({
          'estado': 'En Revisión',
        }).eq('id', event.matriculaId);

        if (event.perfilId.isNotEmpty) {
          await _supabase.from('notificaciones').insert({
            'perfil_id': event.perfilId,
            'titulo': 'Matrícula En Revisión 📋',
            'mensaje': 'Tu solicitud ${event.ticketCode} está siendo evaluada por el área académica.',
            'categoria': 'Matrícula',
            'leido': false,
          });
        }

        final updatedList = currentState.requests.map((req) {
          if (req.matriculaId == event.matriculaId) return req.copyWith(status: 'En Revisión');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      } catch (e) {
        final updatedList = currentState.requests.map((req) {
          if (req.matriculaId == event.matriculaId) return req.copyWith(status: 'En Revisión');
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      }
    }
  }

  Future<void> _onRejectDirectly(
    RejectEnrollmentDirectlyRequested event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminLoaded) {
      try {
        await _supabase.from('matriculas').update({
          'estado': 'Rechazado',
          'observaciones': event.reason,
        }).eq('id', event.matriculaId);

        if (event.perfilId.isNotEmpty) {
          await _supabase.from('notificaciones').insert({
            'perfil_id': event.perfilId,
            'titulo': 'Matrícula Rechazada ❌',
            'mensaje': 'Tu solicitud ${event.ticketCode} fue rechazada por el siguiente motivo: ${event.reason}',
            'categoria': 'Matrícula',
            'leido': false,
          });
        }

        final updatedList = currentState.requests.map((req) {
          if (req.matriculaId == event.matriculaId) {
            return req.copyWith(status: 'Rechazado', observations: event.reason);
          }
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      } catch (e) {
        final updatedList = currentState.requests.map((req) {
          if (req.matriculaId == event.matriculaId) {
            return req.copyWith(status: 'Rechazado', observations: event.reason);
          }
          return req;
        }).toList();
        _emitLoadedState(emit, updatedList, currentState.activeStatusFilter, currentState.activeModeFilter);
      }
    }
  }

  void _emitLoadedState(
    Emitter<AdminState> emit,
    List<AdminEnrollmentRequest> list,
    String statusFilter,
    String modeFilter,
  ) {
    final total = list.length;
    final approved = list.where((r) => r.status == 'Aprobado').length;
    final pending = list.where((r) => r.status == 'Pendiente').length;
    final observed = list.where((r) => r.status == 'Observado').length;
    final underReview = list.where((r) => r.status == 'En Revisión').length;
    final rejected = list.where((r) => r.status == 'Rechazado').length;

    emit(AdminLoaded(
      stats: AdminStats(
        totalRequests: total,
        approvedCount: approved,
        pendingCount: pending,
        observedCount: observed,
        underReviewCount: underReview,
        rejectedCount: rejected,
      ),
      requests: list,
      activeStatusFilter: statusFilter,
      activeModeFilter: modeFilter,
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
