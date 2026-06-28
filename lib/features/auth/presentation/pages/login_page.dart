import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.user.role == UserRole.admin) {
            context.go(AppRoutes.adminPanel);
          } else {
            context.go(AppRoutes.home);
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // --- Logo ---
                  const Center(child: AppLogo(size: LogoSize.medium)),
                  const SizedBox(height: 40),

                  // --- Header ---
                  Text(
                    'Bienvenido de vuelta',
                    style: AppTypography.headlineXl(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar con tu proceso de matrícula.',
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // --- Campos ---
                  AppTextField(
                    label: 'Correo electrónico',
                    hint: 'ejemplo@ceba.edu.pe',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Contraseña',
                    hint: '••••••••',
                    controller: _passwordCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // --- Olvidé contraseña ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: AppTypography.labelLg(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Botón ---
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return AppButton(
                        label: 'Iniciar sesión',
                        loading: state is AuthLoading,
                        onPressed: () => _submit(context),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- Divider ---
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'o',
                          style: AppTypography.labelLg(
                              color: AppColors.onSurfaceVariant),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Registro ---
                  AppButton(
                    label: 'Crear cuenta nueva',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => context.push(AppRoutes.register),
                  ),
                  const SizedBox(height: 32),

                  // --- Pie ---
                  Center(
                    child: Text(
                      'CEBA Go © 2025 — Portal de Matrícula',
                      style: AppTypography.labelSm(color: AppColors.outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
