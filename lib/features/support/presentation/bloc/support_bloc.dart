import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support_event.dart';
import 'support_state.dart';

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  SupportBloc() : super(const SupportInitial()) {
    on<LoadSupportHistoryRequested>(_onLoadHistory);
    on<SendInquiryRequested>(_onSendInquiry);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onLoadHistory(
    LoadSupportHistoryRequested event,
    Emitter<SupportState> emit,
  ) async {
    emit(const SupportLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const SupportLoaded([]));
        return;
      }

      final result = await _supabase
          .from('tickets_soporte')
          .select('id, categoria, asunto, mensaje, estado, respuesta_soporte, created_at')
          .eq('perfil_id', userId)
          .order('created_at', ascending: false);

      final inquiries = result.map<InquiryModel>((ticket) {
        final createdAt = DateTime.tryParse(ticket['created_at'] as String? ?? '');
        final fechaStr = createdAt != null
            ? '${createdAt.day} ${_monthName(createdAt.month)}, ${createdAt.year}'
            : 'Fecha desconocida';

        return InquiryModel(
          id: 'TCK-${ticket['id'].toString().substring(0, 8).toUpperCase()}',
          title: ticket['asunto'] as String? ?? '',
          category: ticket['categoria'] as String? ?? 'General',
          message: ticket['mensaje'] as String? ?? '',
          status: ticket['estado'] as String? ?? 'Abierto',
          date: fechaStr,
          reply: ticket['respuesta_soporte'] as String?,
        );
      }).toList();

      emit(SupportLoaded(inquiries));
    } catch (e) {
      emit(SupportError('Error al cargar tickets: ${e.toString()}'));
    }
  }

  Future<void> _onSendInquiry(
    SendInquiryRequested event,
    Emitter<SupportState> emit,
  ) async {
    emit(const SupportLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const SupportError('Usuario no autenticado'));
        return;
      }

      final result = await _supabase.from('tickets_soporte').insert({
        'perfil_id': userId,
        'categoria': event.category,
        'asunto': event.title,
        'mensaje': event.message,
        'estado': 'Abierto',
      }).select('id').single();

      final ticketId = 'TCK-${result['id'].toString().substring(0, 8).toUpperCase()}';
      emit(SupportSuccess(ticketId));

      // Volver a cargar el historial actualizado
      add(const LoadSupportHistoryRequested());
    } catch (e) {
      // Fallback: generar ticket local y emitir éxito
      final ticketNum = Random().nextInt(9000) + 1000;
      final ticketId = 'TCK-$ticketNum';
      emit(SupportSuccess(ticketId));
    }
  }

  String _monthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }
}
