import 'package:equatable/equatable.dart';

class RequiredDocument extends Equatable {
  final String id;
  final String name;
  // types: 'dni', 'primary', 'secondary', 'photo', 'birth_cert', 'disability_doc'
  final String type;
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
  final String status; // 'Aprobado', 'En Proceso', 'Observado', 'Finalizado', 'Rechazado'
  final String date;
  final String remarks;
  final String studyMode;

  const HistoricalEnrollment({
    required this.id,
    required this.cycle,
    required this.year,
    required this.status,
    required this.date,
    required this.remarks,
    this.studyMode = '',
  });

  @override
  List<Object?> get props => [id, cycle, year, status, date, remarks, studyMode];
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
  // ── Existing personal fields ─────────────────────────────────────────────
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

  // ── New CEBA personal fields ─────────────────────────────────────────────
  final String sex;        // 'Masculino' | 'Femenino' | 'Otro'
  final String birthDate;  // 'YYYY-MM-DD' or 'DD/MM/AAAA'
  final String email;
  final String address;

  // ── New CEBA academic fields ──────────────────────────────────────────────
  final String lastSchool;
  final String lastGradeCompleted;
  final String lastStudyYear;
  final bool hasLongAbsence;
  final bool requestsPlacementTest;
  final bool isAcademicDataSubmitted;

  // ── New CEBA special options ──────────────────────────────────────────────
  final bool requestsReligionExemption;
  final bool requestsPEExemption;
  final String studyMode;  // 'Presencial' | 'Semi-presencial' | 'A Distancia'
  final bool hasDisability;
  final bool isSpecialOptionsSubmitted;

  // ── Admin observations ────────────────────────────────────────────────────
  final String observations;

  const EnrollmentActiveState({
    // Existing
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
    // New personal
    this.sex = 'Masculino',
    this.birthDate = '',
    this.email = '',
    this.address = '',
    // New academic
    this.lastSchool = '',
    this.lastGradeCompleted = '',
    this.lastStudyYear = '',
    this.hasLongAbsence = false,
    this.requestsPlacementTest = false,
    this.isAcademicDataSubmitted = false,
    // New special options
    this.requestsReligionExemption = false,
    this.requestsPEExemption = false,
    this.studyMode = 'Presencial',
    this.hasDisability = false,
    this.isSpecialOptionsSubmitted = false,
    // Admin
    this.observations = '',
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
    // New personal
    String? sex,
    String? birthDate,
    String? email,
    String? address,
    // New academic
    String? lastSchool,
    String? lastGradeCompleted,
    String? lastStudyYear,
    bool? hasLongAbsence,
    bool? requestsPlacementTest,
    bool? isAcademicDataSubmitted,
    // New special options
    bool? requestsReligionExemption,
    bool? requestsPEExemption,
    String? studyMode,
    bool? hasDisability,
    bool? isSpecialOptionsSubmitted,
    // Admin
    String? observations,
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
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      address: address ?? this.address,
      lastSchool: lastSchool ?? this.lastSchool,
      lastGradeCompleted: lastGradeCompleted ?? this.lastGradeCompleted,
      lastStudyYear: lastStudyYear ?? this.lastStudyYear,
      hasLongAbsence: hasLongAbsence ?? this.hasLongAbsence,
      requestsPlacementTest: requestsPlacementTest ?? this.requestsPlacementTest,
      isAcademicDataSubmitted: isAcademicDataSubmitted ?? this.isAcademicDataSubmitted,
      requestsReligionExemption: requestsReligionExemption ?? this.requestsReligionExemption,
      requestsPEExemption: requestsPEExemption ?? this.requestsPEExemption,
      studyMode: studyMode ?? this.studyMode,
      hasDisability: hasDisability ?? this.hasDisability,
      isSpecialOptionsSubmitted: isSpecialOptionsSubmitted ?? this.isSpecialOptionsSubmitted,
      observations: observations ?? this.observations,
    );
  }

  @override
  List<Object?> get props => [
        fullName, dni, phone, age, cycle,
        isPersonalDataSubmitted,
        documents, overallProgress, isSubmitting,
        hasAvailableVacancy, availableVacanciesCount, enrollmentStatus,
        sex, birthDate, email, address,
        lastSchool, lastGradeCompleted, lastStudyYear,
        hasLongAbsence, requestsPlacementTest, isAcademicDataSubmitted,
        requestsReligionExemption, requestsPEExemption, studyMode,
        hasDisability, isSpecialOptionsSubmitted, observations,
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
