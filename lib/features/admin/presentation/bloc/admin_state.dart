import 'package:equatable/equatable.dart';

class AdminEnrollmentRequest extends Equatable {
  final String id; // codigo_ticket
  final String studentName;
  final String cycle;
  final String date;
  final String status; // 'Pendiente', 'En Revisión', 'Aprobado', 'Observado', 'Rechazado'
  final String dni;
  final String perfilId; // UUID del perfil del estudiante (para notificaciones)
  final String matriculaId; // UUID real de la matrícula en BD

  // Extended fields
  final String phone;
  final String email;
  final String studyMode;
  final String observations;
  final String urlDni;
  final String urlPhoto;
  final String urlCert;
  final String urlDisabilityDoc;
  final bool hasDisability;
  final bool requestsPlacementTest;

  const AdminEnrollmentRequest({
    required this.id,
    required this.studentName,
    required this.cycle,
    required this.date,
    required this.status,
    required this.dni,
    this.perfilId = '',
    this.matriculaId = '',
    this.phone = '',
    this.email = '',
    this.studyMode = 'Presencial',
    this.observations = '',
    this.urlDni = '',
    this.urlPhoto = '',
    this.urlCert = '',
    this.urlDisabilityDoc = '',
    this.hasDisability = false,
    this.requestsPlacementTest = false,
  });

  AdminEnrollmentRequest copyWith({
    String? status,
    String? perfilId,
    String? matriculaId,
    String? phone,
    String? email,
    String? studyMode,
    String? observations,
    String? urlDni,
    String? urlPhoto,
    String? urlCert,
    String? urlDisabilityDoc,
    bool? hasDisability,
    bool? requestsPlacementTest,
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
      phone: phone ?? this.phone,
      email: email ?? this.email,
      studyMode: studyMode ?? this.studyMode,
      observations: observations ?? this.observations,
      urlDni: urlDni ?? this.urlDni,
      urlPhoto: urlPhoto ?? this.urlPhoto,
      urlCert: urlCert ?? this.urlCert,
      urlDisabilityDoc: urlDisabilityDoc ?? this.urlDisabilityDoc,
      hasDisability: hasDisability ?? this.hasDisability,
      requestsPlacementTest: requestsPlacementTest ?? this.requestsPlacementTest,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentName,
        cycle,
        date,
        status,
        dni,
        perfilId,
        matriculaId,
        phone,
        email,
        studyMode,
        observations,
        urlDni,
        urlPhoto,
        urlCert,
        urlDisabilityDoc,
        hasDisability,
        requestsPlacementTest,
      ];
}

class AdminStats extends Equatable {
  final int totalRequests;
  final int approvedCount;
  final int pendingCount;
  final int observedCount;
  final int underReviewCount;
  final int rejectedCount;

  const AdminStats({
    required this.totalRequests,
    required this.approvedCount,
    required this.pendingCount,
    required this.observedCount,
    this.underReviewCount = 0,
    this.rejectedCount = 0,
  });

  @override
  List<Object?> get props => [
        totalRequests,
        approvedCount,
        pendingCount,
        observedCount,
        underReviewCount,
        rejectedCount,
      ];
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
  final String activeStatusFilter;
  final String activeModeFilter;

  const AdminLoaded({
    required this.stats,
    required this.requests,
    this.activeStatusFilter = '',
    this.activeModeFilter = '',
  });

  @override
  List<Object?> get props => [stats, requests, activeStatusFilter, activeModeFilter];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
