import 'package:equatable/equatable.dart';

class AdminEnrollmentRequest extends Equatable {
  final String id; // codigo_ticket
  final String studentName;
  final String cycle;
  final String date;
  final String status; // 'Pendiente', 'Aprobado', 'Observado'
  final String dni;
  final String perfilId; // UUID del perfil del estudiante (para notificaciones)
  final String matriculaId; // UUID real de la matrícula en BD

  const AdminEnrollmentRequest({
    required this.id,
    required this.studentName,
    required this.cycle,
    required this.date,
    required this.status,
    required this.dni,
    this.perfilId = '',
    this.matriculaId = '',
  });

  AdminEnrollmentRequest copyWith({
    String? status,
    String? perfilId,
    String? matriculaId,
  }) {
    return AdminEnrollmentRequest(
      id: id,
      studentName: studentName,
      cycle: cycle,
      date: date,
      status: status ?? this.status,
      dni: dni,
      perfilId: perfilId ?? this.perfilId,
      matriculaId: matriculaId ?? this.matriculaId,
    );
  }

  @override
  List<Object?> get props => [id, studentName, cycle, date, status, dni, perfilId, matriculaId];
}

class AdminStats extends Equatable {
  final int totalRequests;
  final int approvedCount;
  final int pendingCount;
  final int observedCount;

  const AdminStats({
    required this.totalRequests,
    required this.approvedCount,
    required this.pendingCount,
    required this.observedCount,
  });

  @override
  List<Object?> get props => [totalRequests, approvedCount, pendingCount, observedCount];
}

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoaded extends AdminState {
  final AdminStats stats;
  final List<AdminEnrollmentRequest> requests;

  const AdminLoaded({
    required this.stats,
    required this.requests,
  });

  @override
  List<Object?> get props => [stats, requests];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
