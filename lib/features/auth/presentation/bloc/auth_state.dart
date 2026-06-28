import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthForgotPasswordSuccess extends AuthState {
  const AuthForgotPasswordSuccess({required this.email});
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthRegisterSuccess extends AuthState {
  const AuthRegisterSuccess({required this.user});
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}

// ---------- Modelo simple del usuario ----------
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.role,
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String email;
  final UserRole role;

  String get fullName => '$nombres $apellidos';

  @override
  List<Object?> get props => [id, email, role];
}

enum UserRole { student, admin }
