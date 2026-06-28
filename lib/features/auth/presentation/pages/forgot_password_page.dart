import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthForgotPasswordRequested(email: _emailCtrl.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthForgotPasswordSuccess) {
          _showSuccessSheet(context, state.email);
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // --- Ícono ---
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 32,
                      color: AppColors.brandBlack,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Recuperar\ncontraseña',
                    style: AppTypography.headlineXl(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                    style: AppTypography.bodyMd(
                        color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  AppTextField(
                    label: 'Correo electrónico',
                    hint: 'ejemplo@ceba.edu.pe',
                    controller: _emailCtrl,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => AppButton(
                      label: 'Enviar enlace',
                      loading: state is AuthLoading,
                      onPressed: () => _submit(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppButton(
                    label: 'Volver al inicio de sesión',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: AppColors.brandBlack),
            ),
            const SizedBox(height: 20),
            Text('¡Correo enviado!',
                style: AppTypography.headlineMd(color: AppColors.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Hemos enviado un enlace de recuperación a:\n$email',
              textAlign: TextAlign.center,
              style:
                  AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Volver al inicio',
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
