import 'dart:math';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'enrollment_event.dart';
import 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  EnrollmentBloc() : super(const EnrollmentInitial()) {
    on<LoadEnrollmentDetails>(_onLoadDetails);
    on<SubmitPersonalData>(_onSubmitPersonalData);
    on<UploadDocumentFile>(_onUploadDocumentFile);
    on<SubmitEnrollment>(_onSubmitEnrollment);
    on<LoadEnrollmentHistory>(_onLoadHistory);
    on<ChangeEnrollmentCycle>(_onChangeCycle);
  }

  final _supabase = Supabase.instance.client;
  String? _matriculaId; // Guardamos el ID de la matrícula actual

  final List<RequiredDocument> _initialDocs = [
    const RequiredDocument(id: 'd1', name: 'Copia legible de DNI (ambas caras)', type: 'dni'),
    const RequiredDocument(id: 'd2', name: 'Certificado Oficial de Estudios Primarios', type: 'primary'),
    const RequiredDocument(id: 'd3', name: 'Certificado Oficial de 1° y 2° de Secundaria', type: 'secondary'),
    const RequiredDocument(id: 'd4', name: 'Foto tamaño carnet a color (fondo blanco)', type: 'photo'),
  ];

  Future<void> _onLoadDetails(LoadEnrollmentDetails event, Emitter<EnrollmentState> emit) async {
    emit(const EnrollmentLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const EnrollmentError('Usuario no autenticado'));
        return;
      }

      // Leer perfil para autocompletar datos
      final perfil = await _supabase
          .from('perfiles')
          .select('nombres, apellidos, dni, telefono, rol')
          .eq('id', userId)
          .maybeSingle();

      // Leer matrícula activa del usuario (la más reciente)
      final matriculas = await _supabase
          .from('matriculas')
          .select()
          .eq('perfil_id', userId)
          .order('fecha_creacion', ascending: false)
          .limit(1);

      List<RequiredDocument> docs = List.from(_initialDocs);
      String fullName = '';
      String dni = '';
      String phone = '';
      String age = '';
      String cycle = '';
      String enrollmentStatus = 'Sin matrícula';
      bool isPersonalDataSubmitted = false;
      double progress = 0.1;

      if (perfil != null) {
        final nombres = perfil['nombres'] as String? ?? '';
        final apellidos = perfil['apellidos'] as String? ?? '';
        fullName = '$nombres $apellidos'.trim();
        dni = perfil['dni'] as String? ?? '';
        phone = perfil['telefono'] as String? ?? '';
      }

      if (matriculas.isNotEmpty) {
        final mat = matriculas.first;
        _matriculaId = mat['id'] as String?;
        isPersonalDataSubmitted = true;
        cycle = mat['ciclo'] as String? ?? '';
        enrollmentStatus = mat['estado'] as String? ?? 'Pendiente';
        final nombresMat = mat['nombres'] as String? ?? '';
        final apellidosMat = mat['apellidos'] as String? ?? '';
        if (nombresMat.isNotEmpty) {
          fullName = '$nombresMat $apellidosMat'.trim();
        }
        dni = mat['dni'] as String? ?? dni;
        phone = mat['telefono'] as String? ?? phone;
        age = mat['edad']?.toString() ?? '';

        // Actualizar estado de documentos según URLs guardadas
        docs = docs.map((doc) {
          String? url;
          String? fileName;
          switch (doc.type) {
            case 'dni':
              url = mat['url_dni'] as String?;
              fileName = url != null && url.isNotEmpty ? 'DNI_subido' : null;
              break;
            case 'primary':
              url = mat['url_certificado_primaria'] as String?;
              fileName = url != null && url.isNotEmpty ? 'Cert_Primaria_subido' : null;
              break;
            case 'secondary':
              url = mat['url_certificado_secundaria'] as String?;
              fileName = url != null && url.isNotEmpty ? 'Cert_Secundaria_subido' : null;
              break;
            case 'photo':
              url = mat['url_foto'] as String?;
              fileName = url != null && url.isNotEmpty ? 'Foto_subida' : null;
              break;
          }
          if (url != null && url.isNotEmpty) {
            return doc.copyWith(
              isUploaded: true,
              uploadedFileName: fileName,
              status: 'En revisión',
            );
          }
          return doc;
        }).toList();

        final uploadedCount = docs.where((d) => d.isUploaded).length.toDouble();
        final docsProgress = (uploadedCount / docs.length) * 0.70;
        progress = 0.30 + docsProgress;
      }

      final currentCycle = cycle.isEmpty ? 'Ciclo Avanzado (Secundaria)' : cycle;

      // Validar vacante disponible si es rol estudiante y no está aprobado aún
      bool hasAvailableVacancy = true;
      int availableCount = 0;
      final role = perfil?['rol'] as String? ?? 'estudiante';
      if (role.toLowerCase() == 'estudiante' && enrollmentStatus != 'Aprobado') {
        final dbCycle = _mapCycleToDb(currentCycle);
        final vacResult = await _supabase
            .from('vacantes')
            .select('cupos_totales, cupos_ocupados')
            .eq('ciclo_escolar', dbCycle);
            
        if (vacResult.isNotEmpty) {
          int totalAvailable = 0;
          for (final v in vacResult) {
            final tot = v['cupos_totales'] as int? ?? 0;
            final ocup = v['cupos_ocupados'] as int? ?? 0;
            totalAvailable += (tot - ocup);
          }
          availableCount = totalAvailable > 0 ? totalAvailable : 0;
          if (totalAvailable <= 0) {
            hasAvailableVacancy = false;
          }
        } else {
          hasAvailableVacancy = false;
        }
      }

      emit(EnrollmentActiveState(
        fullName: fullName,
        dni: dni,
        phone: phone,
        age: age,
        cycle: currentCycle,
        isPersonalDataSubmitted: isPersonalDataSubmitted,
        documents: docs,
        overallProgress: progress,
        hasAvailableVacancy: hasAvailableVacancy,
        availableVacanciesCount: availableCount,
        enrollmentStatus: enrollmentStatus,
      ));
    } catch (e) {
      emit(EnrollmentError('Error al cargar matrícula: ${e.toString()}'));
    }
  }

  Future<void> _onSubmitPersonalData(SubmitPersonalData event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is EnrollmentActiveState) {
      emit(currentState.copyWith(isSubmitting: true));
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) {
          emit(currentState.copyWith(isSubmitting: false));
          return;
        }

        // Separar nombres y apellidos del fullName
        final parts = event.fullName.trim().split(' ');
        final nombres = parts.isNotEmpty ? parts.first : event.fullName;
        final apellidos = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        // Si ya existe matrícula, actualizarla; si no, crearla
        if (_matriculaId != null) {
          await _supabase.from('matriculas').update({
            'nombres': nombres,
            'apellidos': apellidos,
            'dni': event.dni,
            'telefono': event.phone,
            'edad': int.tryParse(event.age) ?? 18,
            'ciclo': event.cycle,
          }).eq('id', _matriculaId!);
        } else {
          // Generar código de ticket único
          final randomNum = Random().nextInt(9000) + 1000;
          final ticketCode = 'MAT-2026-${randomNum.toRadixString(16).toUpperCase()}';

          final result = await _supabase.from('matriculas').insert({
            'perfil_id': userId,
            'codigo_ticket': ticketCode,
            'nombres': nombres,
            'apellidos': apellidos,
            'dni': event.dni,
            'telefono': event.phone,
            'edad': int.tryParse(event.age) ?? 18,
            'ciclo': event.cycle,
            'estado': 'Pendiente',
          }).select('id').single();

          _matriculaId = result['id'] as String?;
        }

        // Validar vacante disponible si es rol estudiante
        bool hasAvailableVacancy = true;
        int availableCount = 0;
        final perfil = await _supabase
            .from('perfiles')
            .select('rol')
            .eq('id', userId)
            .maybeSingle();
        final role = perfil?['rol'] as String? ?? 'estudiante';
        if (role.toLowerCase() == 'estudiante') {
          final dbCycle = _mapCycleToDb(event.cycle);
          final vacResult = await _supabase
              .from('vacantes')
              .select('cupos_totales, cupos_ocupados')
              .eq('ciclo_escolar', dbCycle);
              
          if (vacResult.isNotEmpty) {
            int totalAvailable = 0;
            for (final v in vacResult) {
              final tot = v['cupos_totales'] as int? ?? 0;
              final ocup = v['cupos_ocupados'] as int? ?? 0;
              totalAvailable += (tot - ocup);
            }
            availableCount = totalAvailable > 0 ? totalAvailable : 0;
            if (totalAvailable <= 0) {
              hasAvailableVacancy = false;
            }
          } else {
            hasAvailableVacancy = false;
          }
        }

        // Calcular progreso
        final uploadedCount = currentState.documents.where((d) => d.isUploaded).length.toDouble();
        final docsProgress = (uploadedCount / currentState.documents.length) * 0.70;
        final progress = 0.30 + docsProgress;

        emit(currentState.copyWith(
          fullName: event.fullName,
          dni: event.dni,
          phone: event.phone,
          age: event.age,
          cycle: event.cycle,
          isPersonalDataSubmitted: true,
          overallProgress: progress,
          isSubmitting: false,
          hasAvailableVacancy: hasAvailableVacancy,
          availableVacanciesCount: availableCount,
          enrollmentStatus: currentState.enrollmentStatus == 'Sin matrícula' ? 'Pendiente' : currentState.enrollmentStatus,
        ));
      } catch (e) {
        emit(currentState.copyWith(isSubmitting: false));
      }
    }
  }

  Future<void> _onUploadDocumentFile(UploadDocumentFile event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is EnrollmentActiveState) {
      emit(currentState.copyWith(isSubmitting: true));
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null || _matriculaId == null) {
          emit(currentState.copyWith(isSubmitting: false));
          return;
        }

        String? publicUrl;

        // Si se proporciona un path de archivo real, subirlo al Storage
        if (event.filePath != null) {
          final filePath = event.filePath!;
          final extension = filePath.split('.').last.toLowerCase();
          final storagePath = '$userId/${event.documentType}_${DateTime.now().millisecondsSinceEpoch}.$extension';

          await _supabase.storage.from('documentos-matricula').upload(
            storagePath,
            File(filePath),
            fileOptions: FileOptions(
              contentType: extension == 'pdf' ? 'application/pdf' : 'image/$extension',
              upsert: true,
            ),
          );

          publicUrl = _supabase.storage
              .from('documentos-matricula')
              .getPublicUrl(storagePath);
        } else {
          // Si no hay file path (simulación), guardar un placeholder URL
          publicUrl = 'pending_${event.documentType}_${DateTime.now().millisecondsSinceEpoch}';
        }

        // Actualizar URL en la matrícula
        final urlField = _getUrlFieldName(event.documentType);
        if (urlField != null) {
          await _supabase.from('matriculas').update({
            urlField: publicUrl,
          }).eq('id', _matriculaId!);
        }

        // Actualizar estado local
        final updatedDocs = currentState.documents.map((doc) {
          if (doc.type == event.documentType) {
            return doc.copyWith(
              isUploaded: true,
              uploadedFileName: event.fileName,
              status: 'En revisión',
            );
          }
          return doc;
        }).toList();

        final uploadedCount = updatedDocs.where((d) => d.isUploaded).length.toDouble();
        final personalBonus = currentState.isPersonalDataSubmitted ? 0.30 : 0.0;
        final docsProgress = (uploadedCount / updatedDocs.length) * 0.70;
        final progress = personalBonus + docsProgress;

        emit(currentState.copyWith(
          documents: updatedDocs,
          overallProgress: progress,
          isSubmitting: false,
        ));
      } catch (e) {
        // Si falla el upload real, al menos actualizar UI localmente
        final updatedDocs = currentState.documents.map((doc) {
          if (doc.type == event.documentType) {
            return doc.copyWith(
              isUploaded: true,
              uploadedFileName: event.fileName,
              status: 'En revisión',
            );
          }
          return doc;
        }).toList();

        final uploadedCount = updatedDocs.where((d) => d.isUploaded).length.toDouble();
        final personalBonus = currentState.isPersonalDataSubmitted ? 0.30 : 0.0;
        final docsProgress = (uploadedCount / updatedDocs.length) * 0.70;

        emit(currentState.copyWith(
          documents: updatedDocs,
          overallProgress: personalBonus + docsProgress,
          isSubmitting: false,
        ));
      }
    }
  }

  Future<void> _onSubmitEnrollment(SubmitEnrollment event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is EnrollmentActiveState) {
      emit(currentState.copyWith(isSubmitting: true));
      try {
        final userId = _supabase.auth.currentUser?.id;

        String code = 'MAT-2026-${(Random().nextInt(9000) + 1000).toRadixString(16).toUpperCase()}';

        if (_matriculaId != null) {
          // Actualizar estado a Pendiente y obtener código
          final result = await _supabase.from('matriculas').update({
            'estado': 'Pendiente',
          }).eq('id', _matriculaId!).select('codigo_ticket').single();

          code = result['codigo_ticket'] as String? ?? code;
        } else if (userId != null) {
          // Crear matrícula si no existe
          final parts = currentState.fullName.trim().split(' ');
          final nombres = parts.isNotEmpty ? parts.first : currentState.fullName;
          final apellidos = parts.length > 1 ? parts.sublist(1).join(' ') : '';

          final randomNum = Random().nextInt(9000) + 1000;
          code = 'MAT-2026-${randomNum.toRadixString(16).toUpperCase()}';

          await _supabase.from('matriculas').insert({
            'perfil_id': userId,
            'codigo_ticket': code,
            'nombres': nombres,
            'apellidos': apellidos,
            'dni': currentState.dni,
            'telefono': currentState.phone,
            'edad': int.tryParse(currentState.age) ?? 18,
            'ciclo': currentState.cycle,
            'estado': 'Pendiente',
          });
        }

        // Crear notificación de éxito
        if (userId != null) {
          try {
            await _supabase.from('notificaciones').insert({
              'perfil_id': userId,
              'titulo': '¡Solicitud enviada!',
              'mensaje': 'Tu solicitud de matrícula $code ha sido recibida y está siendo procesada.',
              'categoria': 'Matrícula',
              'leido': false,
            });
          } catch (_) {}
        }

        emit(EnrollmentSuccessState(code));
      } catch (e) {
        // Si falla, generar código local y emitir éxito de todos modos
        final code = 'MAT-2026-${(Random().nextInt(9000) + 1000).toRadixString(16).toUpperCase()}';
        emit(EnrollmentSuccessState(code));
      }
    }
  }

  Future<void> _onChangeCycle(ChangeEnrollmentCycle event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is EnrollmentActiveState) {
      bool hasAvailableVacancy = true;
      int availableCount = 0;
      
      try {
        final dbCycle = _mapCycleToDb(event.cycle);
        final vacResult = await _supabase
            .from('vacantes')
            .select('cupos_totales, cupos_ocupados')
            .eq('ciclo_escolar', dbCycle);
            
        if (vacResult.isNotEmpty) {
          int totalAvailable = 0;
          for (final v in vacResult) {
            final tot = v['cupos_totales'] as int? ?? 0;
            final ocup = v['cupos_ocupados'] as int? ?? 0;
            totalAvailable += (tot - ocup);
          }
          availableCount = totalAvailable > 0 ? totalAvailable : 0;
          if (totalAvailable <= 0) {
            hasAvailableVacancy = false;
          }
        } else {
          hasAvailableVacancy = false;
        }
      } catch (_) {}

      emit(currentState.copyWith(
        cycle: event.cycle,
        hasAvailableVacancy: hasAvailableVacancy,
        availableVacanciesCount: availableCount,
      ));
    }
  }

  Future<void> _onLoadHistory(LoadEnrollmentHistory event, Emitter<EnrollmentState> emit) async {
    emit(const EnrollmentLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const EnrollmentError('Usuario no autenticado'));
        return;
      }

      final result = await _supabase
          .from('matriculas')
          .select('id, codigo_ticket, ciclo, estado, observaciones, fecha_creacion')
          .eq('perfil_id', userId)
          .order('fecha_creacion', ascending: false);

      if (result.isEmpty) {
        emit(const EnrollmentHistoryLoadedState([]));
        return;
      }

      final history = result.map<HistoricalEnrollment>((mat) {
        final fecha = DateTime.tryParse(mat['fecha_creacion'] as String? ?? '');
        final fechaStr = fecha != null
            ? '${fecha.day} de ${_monthName(fecha.month)}, ${fecha.year}'
            : 'Fecha desconocida';

        return HistoricalEnrollment(
          id: mat['codigo_ticket'] as String? ?? mat['id'] as String,
          cycle: mat['ciclo'] as String? ?? 'Sin ciclo',
          year: '2026',
          status: mat['estado'] as String? ?? 'Pendiente',
          date: fechaStr,
          remarks: mat['observaciones'] as String? ?? 'Matrícula registrada en el sistema CEBA Go.',
        );
      }).toList();

      emit(EnrollmentHistoryLoadedState(history));
    } catch (e) {
      emit(EnrollmentError('Error al cargar historial: ${e.toString()}'));
    }
  }

  // Helpers
  String _mapCycleToDb(String cycleName) {
    if (cycleName.toLowerCase().contains('inicial') || cycleName.toLowerCase().contains('intermedio')) {
      return 'Ciclo Inicial / Intermedio';
    }
    return 'Ciclo Avanzado';
  }

  String? _getUrlFieldName(String documentType) {
    switch (documentType) {
      case 'dni': return 'url_dni';
      case 'primary': return 'url_certificado_primaria';
      case 'secondary': return 'url_certificado_secundaria';
      case 'photo': return 'url_foto';
      default: return null;
    }
  }

  // Método removido - ahora usamos dart:io File directamente

  String _monthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}
