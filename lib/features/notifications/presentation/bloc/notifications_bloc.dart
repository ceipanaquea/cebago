import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc() : super(const NotificationsInitial()) {
    on<LoadNotificationsRequested>(_onLoad);
    on<MarkAsReadRequested>(_onMarkAsRead);
    on<ClearAllRequested>(_onClearAll);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onLoad(
    LoadNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const NotificationsLoaded([]));
        return;
      }

      final result = await _supabase
          .from('notificaciones')
          .select('id, titulo, mensaje, categoria, leido, created_at')
          .eq('perfil_id', userId)
          .order('created_at', ascending: false);

      final notifications = result.map<NotificationModel>((n) {
        final createdAt = DateTime.tryParse(n['created_at'] as String? ?? '');
        final timestamp = createdAt != null ? _formatTimestamp(createdAt) : 'Hoy';

        return NotificationModel(
          id: n['id'] as String,
          title: n['titulo'] as String? ?? '',
          body: n['mensaje'] as String? ?? '',
          timestamp: timestamp,
          category: _mapCategoria(n['categoria'] as String? ?? 'General'),
          isRead: n['leido'] as bool? ?? false,
        );
      }).toList();

      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsError('Error al cargar notificaciones: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      try {
        await _supabase
            .from('notificaciones')
            .update({'leido': true})
            .eq('id', event.id);

        final updatedList = currentState.notifications.map((n) {
          if (n.id == event.id) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        emit(NotificationsLoaded(updatedList));
      } catch (_) {
        // Si falla Supabase, actualizar localmente de todas formas
        final updatedList = currentState.notifications.map((n) {
          if (n.id == event.id) return n.copyWith(isRead: true);
          return n;
        }).toList();
        emit(NotificationsLoaded(updatedList));
      }
    }
  }

  Future<void> _onClearAll(
    ClearAllRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          await _supabase
              .from('notificaciones')
              .update({'leido': true})
              .eq('perfil_id', userId);
        }
        final updatedList = currentState.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        emit(NotificationsLoaded(updatedList));
      } catch (_) {
        final updatedList = currentState.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        emit(NotificationsLoaded(updatedList));
      }
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _mapCategoria(String categoria) {
    switch (categoria) {
      case 'Matrícula': return 'matricula';
      case 'Taller': return 'taller';
      default: return 'general';
    }
  }
}
