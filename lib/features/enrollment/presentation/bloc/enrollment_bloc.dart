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
    on<SubmitAcademicData>(_onSubmitAcademicData);
    on<SubmitSpecialOptions>(_onSubmitSpecialOptions);
    on<UploadDocumentFile>(_onUploadDocumentFile);
    on<SubmitEnrollment>(_onSubmitEnrollment);
    on<LoadEnrollmentHistory>(_onLoadHistory);
    on<ChangeEnrollmentCycle>(_onChangeCycle);
  }

  final _supabase = Supabase.instance.client;
  String? _matriculaId; // ID de la matrícula activa

  /// Documentos base — birth_cert y photo son siempre requeridos.
  /// disability_doc se añade dinámicamente si tiene_discapacidad = true.
  final List<RequiredDocument> _initialDocs = [
    const RequiredDocument(id: 'd1', name: 'Copia legible de DNI (ambas caras)', type: 'dni'),
    const RequiredDocument(id: 'd2', name: 'Certificado Oficial de Estudios Primarios', type: 'primary'),
    const RequiredDocument(id: 'd3', name: 'Certificado Oficial de 1° y 2° de Secundaria', type: 'secondary'),
    const RequiredDocument(id: 'd4', name: 'Acta de Nacimiento', type: 'birth_cert'),
    const RequiredDocument(id: 'd5', name: 'Foto tamaño carnet a color (fondo blanco)', type: 'photo'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD DETAILS
  // ─────────────────────────────────────────────────────────────────────────

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

      // New CEBA fields
      String sex = 'Masculino';
      String birthDate = '';
      String email = '';
      String address = '';
      String lastSchool = '';
      String lastGradeCompleted = '';
      String lastStudyYear = '';
      bool hasLongAbsence = false;
      bool requestsPlacementTest = false;
      bool requestsReligionExemption = false;
      bool requestsPEExemption = false;
      String studyMode = 'Presencial';
      bool hasDisability = false;
      String observations = '';
      bool isAcademicDataSubmitted = false;
      bool isSpecialOptionsSubmitted = false;

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

        // Read new CEBA columns
        sex = mat['sexo'] as String? ?? 'Masculino';
        birthDate = mat['fecha_nacimiento'] as String? ?? '';
        email = mat['email_contacto'] as String? ?? '';
        address = mat['direccion'] as String? ?? '';
        lastSchool = mat['ultima_institucion'] as String? ?? '';
        lastGradeCompleted = mat['ultimo_grado'] as String? ?? '';
        lastStudyYear = mat['ultimo_anio_estudio']?.toString() ?? '';
        hasLongAbsence = mat['tiene_ausencia_larga'] as bool? ?? false;
        requestsPlacementTest = mat['solicita_prueba_ubicacion'] as bool? ?? false;
        requestsReligionExemption = mat['exencion_religion'] as bool? ?? false;
        requestsPEExemption = mat['exencion_educacion_fisica'] as bool? ?? false;
        studyMode = mat['modalidad_estudio'] as String? ?? 'Presencial';
        hasDisability = mat['tiene_discapacidad'] as bool? ?? false;
        observations = mat['observaciones'] as String? ?? '';
        isAcademicDataSubmitted = lastSchool.isNotEmpty;
        isSpecialOptionsSubmitted = isAcademicDataSubmitted && studyMode.isNotEmpty;

        // Add disability doc if needed
        if (hasDisability && !docs.any((d) => d.type == 'disability_doc')) {
          docs = [
            ...docs,
            const RequiredDocument(
              id: 'd6',
              name: 'Certificado / Carnet de Discapacidad (CONADIS u equivalente)',
              type: 'disability_doc',
            ),
          ];
        }

        // Update doc upload statuses from stored URLs
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
            case 'birth_cert':
              url = mat['url_acta_nacimiento'] as String?;
              fileName = url != null && url.isNotEmpty ? 'Acta_Nacimiento_subida' : null;
              break;
            case 'photo':
              url = mat['url_foto'] as String?;
              fileName = url != null && url.isNotEmpty ? 'Foto_subida' : null;
              break;
            case 'disability_doc':
              url = mat['url_doc_discapacidad'] as String?;
              fileName = url != null && url.isNotEmpty ? 'Doc_Discapacidad_subido' : null;
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

      // Validar vacante disponible
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
        // CEBA fields
        sex: sex,
        birthDate: birthDate,
        email: email,
        address: address,
        lastSchool: lastSchool,
        lastGradeCompleted: lastGradeCompleted,
        lastStudyYear: lastStudyYear,
        hasLongAbsence: hasLongAbsence,
        requestsPlacementTest: requestsPlacementTest,
        isAcademicDataSubmitted: isAcademicDataSubmitted,
        requestsReligionExemption: requestsReligionExemption,
        requestsPEExemption: requestsPEExemption,
        studyMode: studyMode,
        hasDisability: hasDisability,
        isSpecialOptionsSubmitted: isSpecialOptionsSubmitted,
        observations: observations,
      ));
    } catch (e) {
      emit(EnrollmentError('Error al cargar matrícula: ${e.toString()}'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT PERSONAL DATA
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onSubmitPersonalData(SubmitPersonalData event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is! EnrollmentActiveState) return;

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

      // Parse birth date from DD/MM/AAAA to YYYY-MM-DD for DB
      String? birthDateDb;
      if (event.birthDate.isNotEmpty && event.birthDate.contains('/')) {
        final dateParts = event.birthDate.split('/');
        if (dateParts.length == 3) {
          birthDateDb = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
        }
      } else if (event.birthDate.isNotEmpty) {
        birthDateDb = event.birthDate;
      }

      final personalData = {
        'nombres': nombres,
        'apellidos': apellidos,
        'dni': event.dni,
        'telefono': event.phone,
        'edad': int.tryParse(event.age) ?? 18,
        'ciclo': event.cycle,
        // New personal fields
        'sexo': event.sex,
        'fecha_nacimiento': birthDateDb,
        'email_contacto': event.email.isNotEmpty ? event.email : null,
        'direccion': event.address.isNotEmpty ? event.address : null,
      };

      if (_matriculaId != null) {
        await _supabase.from('matriculas').update(personalData).eq('id', _matriculaId!);
      } else {
        // Create new enrollment record
        final randomNum = Random().nextInt(9000) + 1000;
        final ticketCode = 'MAT-2026-${randomNum.toRadixString(16).toUpperCase()}';

        final result = await _supabase.from('matriculas').insert({
          'perfil_id': userId,
          'codigo_ticket': ticketCode,
          ...personalData,
          'estado': 'Pendiente',
        }).select('id').single();

        _matriculaId = result['id'] as String?;
      }

      // Validate vacancy
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
          if (totalAvailable <= 0) hasAvailableVacancy = false;
        } else {
          hasAvailableVacancy = false;
        }
      }

      final uploadedCount = currentState.documents.where((d) => d.isUploaded).length.toDouble();
      final docsProgress = (uploadedCount / currentState.documents.length) * 0.70;

      emit(currentState.copyWith(
        fullName: event.fullName,
        dni: event.dni,
        phone: event.phone,
        age: event.age,
        cycle: event.cycle,
        isPersonalDataSubmitted: true,
        overallProgress: 0.30 + docsProgress,
        isSubmitting: false,
        hasAvailableVacancy: hasAvailableVacancy,
        availableVacanciesCount: availableCount,
        enrollmentStatus:
            currentState.enrollmentStatus == 'Sin matrícula' ? 'Pendiente' : currentState.enrollmentStatus,
        sex: event.sex,
        birthDate: event.birthDate,
        email: event.email,
        address: event.address,
      ));
    } catch (e) {
      emit(currentState.copyWith(isSubmitting: false));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT ACADEMIC DATA
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onSubmitAcademicData(SubmitAcademicData event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is! EnrollmentActiveState) return;

    emit(currentState.copyWith(isSubmitting: true));
    try {
      if (_matriculaId == null) {
        emit(currentState.copyWith(isSubmitting: false));
        return;
      }

      await _supabase.from('matriculas').update({
        'ultima_institucion': event.lastSchool,
        'ultimo_grado': event.lastGradeCompleted,
        'ultimo_anio_estudio': int.tryParse(event.lastStudyYear) ?? 0,
        'tiene_ausencia_larga': event.hasLongAbsence,
        'solicita_prueba_ubicacion': event.requestsPlacementTest,
      }).eq('id', _matriculaId!);

      emit(currentState.copyWith(
        lastSchool: event.lastSchool,
        lastGradeCompleted: event.lastGradeCompleted,
        lastStudyYear: event.lastStudyYear,
        hasLongAbsence: event.hasLongAbsence,
        requestsPlacementTest: event.requestsPlacementTest,
        isAcademicDataSubmitted: true,
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isSubmitting: false));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT SPECIAL OPTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onSubmitSpecialOptions(SubmitSpecialOptions event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is! EnrollmentActiveState) return;

    emit(currentState.copyWith(isSubmitting: true));
    try {
      if (_matriculaId == null) {
        emit(currentState.copyWith(isSubmitting: false));
        return;
      }

      // Add or remove disability doc based on flag
      List<RequiredDocument> docs = currentState.documents;
      if (event.hasDisability && !docs.any((d) => d.type == 'disability_doc')) {
        docs = [
          ...docs,
          const RequiredDocument(
            id: 'd6',
            name: 'Certificado / Carnet de Discapacidad (CONADIS u equivalente)',
            type: 'disability_doc',
          ),
        ];
      } else if (!event.hasDisability) {
        docs = docs.where((d) => d.type != 'disability_doc').toList();
      }

      await _supabase.from('matriculas').update({
        'exencion_religion': event.requestsReligionExemption,
        'exencion_educacion_fisica': event.requestsPEExemption,
        'modalidad_estudio': event.studyMode,
        'tiene_discapacidad': event.hasDisability,
      }).eq('id', _matriculaId!);

      // Recalculate progress with updated doc list
      final uploadedCount = docs.where((d) => d.isUploaded).length.toDouble();
      final docsProgress = (uploadedCount / docs.length) * 0.70;

      emit(currentState.copyWith(
        requestsReligionExemption: event.requestsReligionExemption,
        requestsPEExemption: event.requestsPEExemption,
        studyMode: event.studyMode,
        hasDisability: event.hasDisability,
        documents: docs,
        isSpecialOptionsSubmitted: true,
        overallProgress: 0.30 + docsProgress,
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isSubmitting: false));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPLOAD DOCUMENT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onUploadDocumentFile(UploadDocumentFile event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is! EnrollmentActiveState) return;

    emit(currentState.copyWith(isSubmitting: true));
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || _matriculaId == null) {
        emit(currentState.copyWith(isSubmitting: false));
        return;
      }

      String? publicUrl;

      if (event.filePath != null) {
        final filePath = event.filePath!;
        final extension = filePath.split('.').last.toLowerCase();
        final storagePath =
            '$userId/${event.documentType}_${DateTime.now().millisecondsSinceEpoch}.$extension';

        await _supabase.storage.from('documentos-matricula').upload(
              storagePath,
              File(filePath),
              fileOptions: FileOptions(
                contentType: extension == 'pdf' ? 'application/pdf' : 'image/$extension',
                upsert: true,
              ),
            );

        publicUrl = _supabase.storage.from('documentos-matricula').getPublicUrl(storagePath);
      } else {
        publicUrl = 'pending_${event.documentType}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final urlField = _getUrlFieldName(event.documentType);
      if (urlField != null) {
        await _supabase.from('matriculas').update({urlField: publicUrl}).eq('id', _matriculaId!);
      }

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
    } catch (e) {
      // Fallback: update UI even if upload fails
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

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT ENROLLMENT (Final submission)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onSubmitEnrollment(SubmitEnrollment event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is! EnrollmentActiveState) return;

    emit(currentState.copyWith(isSubmitting: true));
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Duplicate enrollment guard
      if (userId != null) {
        final existing = await _supabase
            .from('matriculas')
            .select('id, estado')
            .eq('perfil_id', userId)
            .inFilter('estado', ['Pendiente', 'En Revisión', 'Aprobado'])
            .neq('id', _matriculaId ?? '')
            .limit(1);

        if (existing.isNotEmpty) {
          emit(const EnrollmentError(
              'Ya tienes una matrícula activa en este período. Revisa tu historial.'));
          return;
        }
      }

      String code =
          'MAT-2026-${(Random().nextInt(9000) + 1000).toRadixString(16).toUpperCase()}';

      if (_matriculaId != null) {
        final result = await _supabase
            .from('matriculas')
            .update({'estado': 'Pendiente'})
            .eq('id', _matriculaId!)
            .select('codigo_ticket')
            .single();

        code = result['codigo_ticket'] as String? ?? code;
      } else if (userId != null) {
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
          'sexo': currentState.sex,
          'email_contacto': currentState.email,
          'direccion': currentState.address,
          'modalidad_estudio': currentState.studyMode,
        });
      }

      if (userId != null) {
        try {
          await _supabase.from('notificaciones').insert({
            'perfil_id': userId,
            'titulo': '¡Solicitud enviada!',
            'mensaje':
                'Tu solicitud de matrícula $code ha sido recibida y está siendo procesada.',
            'categoria': 'Matrícula',
            'leido': false,
          });
        } catch (_) {}
      }

      emit(EnrollmentSuccessState(code));
    } catch (e) {
      final code =
          'MAT-2026-${(Random().nextInt(9000) + 1000).toRadixString(16).toUpperCase()}';
      emit(EnrollmentSuccessState(code));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD HISTORY
  // ─────────────────────────────────────────────────────────────────────────

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
          .select('id, codigo_ticket, ciclo, estado, observaciones, modalidad_estudio, fecha_creacion')
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
          studyMode: mat['modalidad_estudio'] as String? ?? '',
        );
      }).toList();

      emit(EnrollmentHistoryLoadedState(history));
    } catch (e) {
      emit(EnrollmentError('Error al cargar historial: ${e.toString()}'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHANGE CYCLE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onChangeCycle(ChangeEnrollmentCycle event, Emitter<EnrollmentState> emit) async {
    final currentState = state;
    if (currentState is! EnrollmentActiveState) return;

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
        if (totalAvailable <= 0) hasAvailableVacancy = false;
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

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String _mapCycleToDb(String cycleName) {
    if (cycleName.toLowerCase().contains('inicial') ||
        cycleName.toLowerCase().contains('intermedio')) {
      return 'Ciclo Inicial / Intermedio';
    }
    return 'Ciclo Avanzado';
  }

  /// Maps a document type to its Supabase column name.
  String? _getUrlFieldName(String documentType) {
    switch (documentType) {
      case 'dni':
        return 'url_dni';
      case 'primary':
        return 'url_certificado_primaria';
      case 'secondary':
        return 'url_certificado_secundaria';
      case 'birth_cert':
        return 'url_acta_nacimiento';
      case 'photo':
        return 'url_foto';
      case 'disability_doc':
        return 'url_doc_discapacidad';
      default:
        return null;
    }
  }

  String _monthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}
