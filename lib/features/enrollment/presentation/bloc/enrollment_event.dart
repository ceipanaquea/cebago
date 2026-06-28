import 'package:equatable/equatable.dart';

abstract class EnrollmentEvent extends Equatable {
  const EnrollmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadEnrollmentDetails extends EnrollmentEvent {
  const LoadEnrollmentDetails();
}

/// Step 1 — Personal data + extended personal fields.
class SubmitPersonalData extends EnrollmentEvent {
  final String fullName;
  final String dni;
  final String phone;
  final String age;
  final String cycle;
  // New CEBA personal fields
  final String sex;       // 'Masculino' | 'Femenino' | 'Otro'
  final String birthDate; // 'DD/MM/AAAA' (stored as date after parsing)
  final String email;
  final String address;

  const SubmitPersonalData({
    required this.fullName,
    required this.dni,
    required this.phone,
    required this.age,
    required this.cycle,
    this.sex = 'Masculino',
    this.birthDate = '',
    this.email = '',
    this.address = '',
  });

  @override
  List<Object?> get props => [fullName, dni, phone, age, cycle, sex, birthDate, email, address];
}

/// Step 2 — Academic background.
class SubmitAcademicData extends EnrollmentEvent {
  final String lastSchool;
  final String lastGradeCompleted;
  final String lastStudyYear;
  final bool hasLongAbsence;
  final bool requestsPlacementTest;

  const SubmitAcademicData({
    required this.lastSchool,
    required this.lastGradeCompleted,
    required this.lastStudyYear,
    required this.hasLongAbsence,
    required this.requestsPlacementTest,
  });

  @override
  List<Object?> get props => [lastSchool, lastGradeCompleted, lastStudyYear, hasLongAbsence, requestsPlacementTest];
}

/// Step 3 — Special options (exemptions, study mode, disability).
class SubmitSpecialOptions extends EnrollmentEvent {
  final bool requestsReligionExemption;
  final bool requestsPEExemption;
  final String studyMode; // 'Presencial' | 'Semi-presencial' | 'A Distancia'
  final bool hasDisability;

  const SubmitSpecialOptions({
    required this.requestsReligionExemption,
    required this.requestsPEExemption,
    required this.studyMode,
    required this.hasDisability,
  });

  @override
  List<Object?> get props => [requestsReligionExemption, requestsPEExemption, studyMode, hasDisability];
}

/// Upload a specific document file.
class UploadDocumentFile extends EnrollmentEvent {
  // types: 'dni', 'primary', 'secondary', 'photo', 'birth_cert', 'disability_doc'
  final String documentType;
  final String fileName;
  final String? filePath; // Real file path if available

  const UploadDocumentFile({
    required this.documentType,
    required this.fileName,
    this.filePath,
  });

  @override
  List<Object?> get props => [documentType, fileName, filePath];
}

/// Final submission after all steps are complete.
class SubmitEnrollment extends EnrollmentEvent {
  const SubmitEnrollment();
}

class LoadEnrollmentHistory extends EnrollmentEvent {
  const LoadEnrollmentHistory();
}

class ChangeEnrollmentCycle extends EnrollmentEvent {
  final String cycle;
  const ChangeEnrollmentCycle(this.cycle);

  @override
  List<Object?> get props => [cycle];
}

class SubmitFullEnrollmentData extends EnrollmentEvent {
  final String fullName;
  final String dni;
  final String phone;
  final String age;
  final String cycle;
  final String sex;
  final String birthDate;
  final String email;
  final String address;
  final String lastSchool;
  final String lastGradeCompleted;
  final String lastStudyYear;
  final bool hasLongAbsence;
  final bool requestsPlacementTest;
  final bool requestsReligionExemption;
  final bool requestsPEExemption;
  final String studyMode;
  final bool hasDisability;

  const SubmitFullEnrollmentData({
    required this.fullName,
    required this.dni,
    required this.phone,
    required this.age,
    required this.cycle,
    required this.sex,
    required this.birthDate,
    required this.email,
    required this.address,
    required this.lastSchool,
    required this.lastGradeCompleted,
    required this.lastStudyYear,
    required this.hasLongAbsence,
    required this.requestsPlacementTest,
    required this.requestsReligionExemption,
    required this.requestsPEExemption,
    required this.studyMode,
    required this.hasDisability,
  });

  @override
  List<Object?> get props => [
        fullName,
        dni,
        phone,
        age,
        cycle,
        sex,
        birthDate,
        email,
        address,
        lastSchool,
        lastGradeCompleted,
        lastStudyYear,
        hasLongAbsence,
        requestsPlacementTest,
        requestsReligionExemption,
        requestsPEExemption,
        studyMode,
        hasDisability,
      ];
}
