import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onRefresh);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const HomeError(message: 'Usuario no autenticado'));
        return;
      }

      // Leer perfil del usuario
      final perfil = await _supabase
          .from('perfiles')
          .select('nombres, promedio_general, asistencia')
          .eq('id', userId)
          .maybeSingle();

      final nombres = perfil?['nombres'] as String? ?? 'Estudiante';

      // Leer matrícula activa del usuario
      final matriculas = await _supabase
          .from('matriculas')
          .select('estado, url_dni, url_certificado_primaria, url_certificado_secundaria, url_foto')
          .eq('perfil_id', userId)
          .order('fecha_creacion', ascending: false)
          .limit(1);

      String enrollmentStatus = 'Sin matrícula';
      int pendingDocs = 4;

      if (matriculas.isNotEmpty) {
        final mat = matriculas.first;
        enrollmentStatus = mat['estado'] as String? ?? 'Pendiente';

        // Contar documentos que faltan
        final docsSubidos = [
          mat['url_dni'],
          mat['url_certificado_primaria'],
          mat['url_certificado_secundaria'],
          mat['url_foto'],
        ].where((url) => url != null && (url as String).isNotEmpty).length;

        pendingDocs = 4 - docsSubidos;
      }

      // Contar notificaciones no leídas
      final notifResult = await _supabase
          .from('notificaciones')
          .select('id')
          .eq('perfil_id', userId)
          .eq('leido', false);
      final unreadCount = notifResult.length;

      // Leer últimas notificaciones de categoría General como anuncios
      final notifData = await _supabase
          .from('notificaciones')
          .select('titulo, mensaje, created_at, leido')
          .eq('perfil_id', userId)
          .eq('categoria', 'General')
          .order('created_at', ascending: false)
          .limit(3);

      final announcements = notifData.map<HomeAnnouncement>((n) {
        final createdAt = DateTime.tryParse(n['created_at'] as String? ?? '') ?? DateTime.now();
        return HomeAnnouncement(
          title: n['titulo'] as String? ?? '',
          body: n['mensaje'] as String? ?? '',
          date: createdAt,
          isNew: !(n['leido'] as bool? ?? false),
        );
      }).toList();

      // Si no hay anuncios en BD, mostrar anuncios por defecto
      final finalAnnouncements = announcements.isNotEmpty
          ? announcements
          : [
              HomeAnnouncement(
                title: 'Inicio de matrículas 2026-I',
                body: 'El proceso de matrícula para el período 2026-I ha comenzado. ¡No dejes pasar tu cupo!',
                date: DateTime.now(),
                isNew: true,
              ),
              HomeAnnouncement(
                title: 'Documentos requeridos',
                body: 'Recuerda presentar DNI vigente, foto tamaño carnet y certificado de estudios previos.',
                date: DateTime.now().subtract(const Duration(days: 1)),
                isNew: false,
              ),
            ];

      // Pasos según estado de matrícula
      final hasMatricula = matriculas.isNotEmpty;
      final mat = hasMatricula ? matriculas.first : null;
      final hasDocsDni = mat != null && (mat['url_dni'] as String? ?? '').isNotEmpty;
      final hasDocsCertPrimaria = mat != null && (mat['url_certificado_primaria'] as String? ?? '').isNotEmpty;
      final hasDocsCertSec = mat != null && (mat['url_certificado_secundaria'] as String? ?? '').isNotEmpty;
      final hasFoto = mat != null && (mat['url_foto'] as String? ?? '').isNotEmpty;
      final hasAllDocs = hasDocsDni && hasDocsCertPrimaria && hasDocsCertSec && hasFoto;
      final isApproved = mat != null && mat['estado'] == 'Aprobado';

      final steps = [
        HomeStep(
          title: 'Completar registro',
          description: 'Verifica tus datos personales',
          isCompleted: hasMatricula,
          icon: '✅',
        ),
        HomeStep(
          title: 'Subir documentos',
          description: 'DNI, foto y certificado de estudios',
          isCompleted: hasAllDocs,
          icon: '📄',
        ),
        HomeStep(
          title: 'Enviar solicitud',
          description: 'Completa tu solicitud de matrícula',
          isCompleted: hasMatricula && enrollmentStatus != 'Sin matrícula',
          icon: '📝',
        ),
        HomeStep(
          title: 'Confirmación',
          description: 'Espera la validación del CEBA',
          isCompleted: isApproved,
          icon: '🎓',
        ),
      ];

      emit(HomeLoaded(
        userName: nombres,
        enrollmentStatus: enrollmentStatus,
        pendingDocuments: pendingDocs,
        unreadNotifications: unreadCount,
        nextSteps: steps,
        announcements: finalAnnouncements,
      ));
    } catch (e) {
      emit(HomeError(message: 'Error al cargar datos: ${e.toString()}'));
    }
  }

  Future<void> _onRefresh(HomeRefreshRequested event, Emitter<HomeState> emit) async {
    final userId = _supabase.auth.currentUser?.id ?? '';
    add(HomeLoadRequested(userId: userId));
  }
}
