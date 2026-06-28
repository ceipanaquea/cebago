import 'package:equatable/equatable.dart';

class InquiryModel extends Equatable {
  final String id;
  final String title;
  final String category;
  final String message;
  final String status; // 'Pendiente', 'Respondido'
  final String date;
  final String? reply;

  const InquiryModel({
    required this.id,
    required this.title,
    required this.category,
    required this.message,
    required this.status,
    required this.date,
    this.reply,
  });

  @override
  List<Object?> get props => [id, title, category, message, status, date, reply];
}

abstract class SupportState extends Equatable {
  const SupportState();

  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {
  const SupportInitial();
}

class SupportLoading extends SupportState {
  const SupportLoading();
}

class SupportLoaded extends SupportState {
  final List<InquiryModel> inquiries;
  const SupportLoaded(this.inquiries);

  @override
  List<Object?> get props => [inquiries];
}

class SupportSuccess extends SupportState {
  final String ticketId;
  const SupportSuccess(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class SupportError extends SupportState {
  final String message;
  const SupportError(this.message);

  @override
  List<Object?> get props => [message];
}
