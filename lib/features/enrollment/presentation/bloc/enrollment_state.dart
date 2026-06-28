import 'package:equatable/equatable.dart';

class RequiredDocument extends Equatable {
  final String id;
  final String name;
  final String type; // 'dni', 'primary', 'secondary', 'photo'
  final bool isUploaded;
  final String? uploadedFileName;
  final String status; // 'Pendiente', 'En revisión', 'Aprobado', 'Rechazado'

  const RequiredDocument({
    required this.id,
    required this.name,
    required this.type,
    this.isUploaded = false,
    this.uploadedFileName,
    this.status = 'Pendiente',
  });

  RequiredDocument copyWith({
    bool? isUploaded,
    String? uploadedFileName,
    String? status,
  }) {
    return RequiredDocument(
      id: id,
      name: name,
      type: type,
      isUploaded: isUploaded ?? this.isUploaded,
      uploadedFileName: uploadedFileName ?? this.uploadedFileName,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, name, type, isUploaded, uploadedFileName, status];
}

class HistoricalEnrollment extends Equatable {
  final String id;
  final String cycle;
  final String year;
  final String status; // 'Aprobado', 'En Proceso', 'Observado', 'Finalizado'
  final String date;
  final String remarks;

  const HistoricalEnrollment({
    required this.id,
    required this.cycle,
    required this.year,
    required this.status,
    required this.date,
    required this.remarks,
  });

  @override
  List<Object?> get props => [id, cycle, year, status, date, remarks];
}

abstract class EnrollmentState extends Equatable {
  const EnrollmentState();

  @override
  List<Object?> get props => [];
}

class EnrollmentInitial extends EnrollmentState {
  const EnrollmentInitial();
}

class EnrollmentLoading extends EnrollmentState {
  const EnrollmentLoading();
}

class EnrollmentActiveState extends EnrollmentState {
  final String fullName;
  final String dni;
  final String phone;
  final String age;
  final String cycle;
  final bool isPersonalDataSubmitted;
  final List<RequiredDocument> documents;
  final double overallProgress; // 0.0 to 1.0
  final bool isSubmitting;
  final bool hasAvailableVacancy;
  final int availableVacanciesCount;
  final String enrollmentStatus;

  const EnrollmentActiveState({
    this.fullName = '',
    this.dni = '',
    this.phone = '',
    this.age = '',
    this.cycle = '',
    this.isPersonalDataSubmitted = false,
    required this.documents,
    this.overallProgress = 0.1,
    this.isSubmitting = false,
    this.hasAvailableVacancy = true,
    this.availableVacanciesCount = 0,
    this.enrollmentStatus = 'Sin matrícula',
  });

  EnrollmentActiveState copyWith({
    String? fullName,
    String? dni,
    String? phone,
    String? age,
    String? cycle,
    bool? isPersonalDataSubmitted,
    List<RequiredDocument>? documents,
    double? overallProgress,
    bool? isSubmitting,
    bool? hasAvailableVacancy,
    int? availableVacanciesCount,
    String? enrollmentStatus,
  }) {
    return EnrollmentActiveState(
      fullName: fullName ?? this.fullName,
      dni: dni ?? this.dni,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      cycle: cycle ?? this.cycle,
      isPersonalDataSubmitted: isPersonalDataSubmitted ?? this.isPersonalDataSubmitted,
      documents: documents ?? this.documents,
      overallProgress: overallProgress ?? this.overallProgress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasAvailableVacancy: hasAvailableVacancy ?? this.hasAvailableVacancy,
      availableVacanciesCount: availableVacanciesCount ?? this.availableVacanciesCount,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        dni,
        phone,
        age,
        cycle,
        isPersonalDataSubmitted,
        documents,
        overallProgress,
        isSubmitting,
        hasAvailableVacancy,
        availableVacanciesCount,
        enrollmentStatus,
      ];
}

class EnrollmentSuccessState extends EnrollmentState {
  final String enrollmentCode;
  const EnrollmentSuccessState(this.enrollmentCode);

  @override
  List<Object?> get props => [enrollmentCode];
}

class EnrollmentHistoryLoadedState extends EnrollmentState {
  final List<HistoricalEnrollment> history;
  const EnrollmentHistoryLoadedState(this.history);

  @override
  List<Object?> get props => [history];
}

class EnrollmentError extends EnrollmentState {
  final String message;
  const EnrollmentError(this.message);

  @override
  List<Object?> get props => [message];
}
