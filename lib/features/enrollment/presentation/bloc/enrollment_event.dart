import 'package:equatable/equatable.dart';

abstract class EnrollmentEvent extends Equatable {
  const EnrollmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadEnrollmentDetails extends EnrollmentEvent {
  const LoadEnrollmentDetails();
}

class SubmitPersonalData extends EnrollmentEvent {
  final String fullName;
  final String dni;
  final String phone;
  final String age;
  final String cycle;

  const SubmitPersonalData({
    required this.fullName,
    required this.dni,
    required this.phone,
    required this.age,
    required this.cycle,
  });

  @override
  List<Object?> get props => [fullName, dni, phone, age, cycle];
}

class UploadDocumentFile extends EnrollmentEvent {
  final String documentType; // 'dni', 'primary', 'secondary', 'photo'
  final String fileName;
  final String? filePath; // Ruta real del archivo si está disponible

  const UploadDocumentFile({
    required this.documentType,
    required this.fileName,
    this.filePath,
  });

  @override
  List<Object?> get props => [documentType, fileName, filePath];
}

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

