import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminDataRequested extends AdminEvent {
  const LoadAdminDataRequested();
}

class ApproveEnrollmentRequested extends AdminEvent {
  final String id; // codigo_ticket o id
  const ApproveEnrollmentRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class RejectEnrollmentRequested extends AdminEvent {
  final String id;
  final String? observaciones;
  const RejectEnrollmentRequested(this.id, {this.observaciones});

  @override
  List<Object?> get props => [id, observaciones];
}

class FilterEnrollmentsRequested extends AdminEvent {
  final String status;
  final String mode;
  const FilterEnrollmentsRequested({this.status = '', this.mode = ''});

  @override
  List<Object?> get props => [status, mode];
}

class AddObservationRequested extends AdminEvent {
  final String matriculaId;
  final String perfilId;
  final String ticketCode;
  final String observationText;

  const AddObservationRequested({
    required this.matriculaId,
    required this.perfilId,
    required this.ticketCode,
    required this.observationText,
  });

  @override
  List<Object?> get props => [matriculaId, perfilId, ticketCode, observationText];
}

class MarkUnderReviewRequested extends AdminEvent {
  final String matriculaId;
  final String perfilId;
  final String ticketCode;

  const MarkUnderReviewRequested({
    required this.matriculaId,
    required this.perfilId,
    required this.ticketCode,
  });

  @override
  List<Object?> get props => [matriculaId, perfilId, ticketCode];
}

class RejectEnrollmentDirectlyRequested extends AdminEvent {
  final String matriculaId;
  final String perfilId;
  final String ticketCode;
  final String reason;

  const RejectEnrollmentDirectlyRequested({
    required this.matriculaId,
    required this.perfilId,
    required this.ticketCode,
    required this.reason,
  });

  @override
  List<Object?> get props => [matriculaId, perfilId, ticketCode, reason];
}
