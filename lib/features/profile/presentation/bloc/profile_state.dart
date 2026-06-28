import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final String studentId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String currentCycle;
  final bool isAdmin;
  final String attendanceRate; // e.g. "94%"
  final String academicAverages; // e.g. "17.2 / 20"

  const ProfileLoaded({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.currentCycle,
    this.isAdmin = true, // Activamos por defecto para mostrar el gateway de Admin Panel
    required this.attendanceRate,
    required this.academicAverages,
  });

  ProfileLoaded copyWith({
    String? studentId,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? currentCycle,
    bool? isAdmin,
    String? attendanceRate,
    String? academicAverages,
  }) {
    return ProfileLoaded(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currentCycle: currentCycle ?? this.currentCycle,
      isAdmin: isAdmin ?? this.isAdmin,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      academicAverages: academicAverages ?? this.academicAverages,
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        fullName,
        email,
        phone,
        address,
        currentCycle,
        isAdmin,
        attendanceRate,
        academicAverages,
      ];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
