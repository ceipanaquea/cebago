import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.rol,
  });
  final String nombres;
  final String apellidos;
  final String dni;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final String rol;
  @override
  List<Object?> get props =>
      [nombres, apellidos, dni, email, phone, password, confirmPassword, rol];
}

class AuthForgotPasswordRequested extends AuthEvent {
  const AuthForgotPasswordRequested({required this.email});
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}
