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
