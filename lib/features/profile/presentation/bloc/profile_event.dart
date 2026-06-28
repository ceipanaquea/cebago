import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileRequested extends ProfileEvent {
  const LoadProfileRequested();
}

class UpdateDetailsRequested extends ProfileEvent {
  final String email;
  final String phone;
  final String address;

  const UpdateDetailsRequested({
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  List<Object?> get props => [email, phone, address];
}
