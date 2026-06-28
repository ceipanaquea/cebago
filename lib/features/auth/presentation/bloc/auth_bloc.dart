import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckStatusRequested>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthLogoutRequested>(_onLogout);
  }

  final _supabase = supa.Supabase.instance.client;

  Future<void> _onCheckStatus(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final perfil = await _supabase
              .from('perfiles')
              .select('nombres, apellidos, rol')
              .eq('id', user.id)
              .maybeSingle();

          final rol = perfil?['rol'] as String? ?? 'estudiante';
          final role = rol == 'administrador' || rol == 'director'
              ? UserRole.admin
              : UserRole.student;

          emit(AuthAuthenticated(
            user: AuthUser(
              id: user.id,
              nombres: perfil?['nombres'] as String? ?? '',
              apellidos: perfil?['apellidos'] as String? ?? '',
              email: user.email ?? '',
              role: role,
            ),
          ));
          return;
        }
      }
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(const AuthError(message: 'Por favor completa todos los campos'));
        return;
      }

      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      final user = response.user;
      if (user == null) {
        emit(const AuthError(message: 'No se pudo iniciar sesión'));
        return;
      }

      final perfil = await _supabase
          .from('perfiles')
          .select('nombres, apellidos, rol')
          .eq('id', user.id)
          .maybeSingle();

      final rol = perfil?['rol'] as String? ?? 'estudiante';
      final role = rol == 'administrador' || rol == 'director'
          ? UserRole.admin
          : UserRole.student;

      emit(AuthAuthenticated(
        user: AuthUser(
          id: user.id,
          nombres: perfil?['nombres'] as String? ?? '',
          apellidos: perfil?['apellidos'] as String? ?? '',
          email: user.email ?? '',
          role: role,
        ),
      ));
    } on supa.AuthException catch (e) {
      emit(AuthError(message: _mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      if (event.password != event.confirmPassword) {
        emit(const AuthError(message: 'Las contraseñas no coinciden'));
        return;
      }

      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
        data: {
          'nombres': event.nombres,
          'apellidos': event.apellidos,
          'dni': event.dni,
          'telefono': event.phone,
          'rol': event.rol,
        },
      );

      final user = response.user;
      if (user == null) {
        emit(const AuthError(message: 'No se pudo crear la cuenta'));
        return;
      }

      emit(AuthRegisterSuccess(
        user: AuthUser(
          id: user.id,
          nombres: event.nombres,
          apellidos: event.apellidos,
          email: event.email,
          role: event.rol == 'administrador' || event.rol == 'director'
              ? UserRole.admin
              : UserRole.student,
        ),
      ));
    } on supa.AuthException catch (e) {
      emit(AuthError(message: _mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _supabase.auth.resetPasswordForEmail(event.email);
      emit(AuthForgotPasswordSuccess(email: event.email));
    } on supa.AuthException catch (e) {
      emit(AuthError(message: _mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    emit(const AuthUnauthenticated());
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Por favor confirma tu correo electrónico';
    }
    if (message.contains('User already registered') ||
        message.contains('already registered')) {
      return 'Este correo ya está registrado';
    }
    if (message.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (message.contains('Unable to validate email address')) {
      return 'Formato de correo inválido';
    }
    return message;
  }
}
