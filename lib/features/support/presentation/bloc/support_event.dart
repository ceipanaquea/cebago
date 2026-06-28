import 'package:equatable/equatable.dart';

abstract class SupportEvent extends Equatable {
  const SupportEvent();

  @override
  List<Object?> get props => [];
}

class LoadSupportHistoryRequested extends SupportEvent {
  const LoadSupportHistoryRequested();
}

class SendInquiryRequested extends SupportEvent {
  final String title;
  final String category;
  final String message;

  const SendInquiryRequested({
    required this.title,
    required this.category,
    required this.message,
  });

  @override
  List<Object?> get props => [title, category, message];
}
