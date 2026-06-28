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
import '../../../../core/widgets/app_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _acceptTerms = false;
  String _selectedRol = 'estudiante';

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthRegisterRequested(
            nombres: _nombresCtrl.text.trim(),
            apellidos: _apellidosCtrl.text.trim(),
            dni: _dniCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passwordCtrl.text,
            confirmPassword: _confirmPasswordCtrl.text,
            rol: _selectedRol,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess) {
          context.go(AppRoutes.home);
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
          title: const Text('Crear cuenta'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // --- Header ---
                  Text('Registro de\nUsuario',
                      style: AppTypography.headlineXl(
                          color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    'Completa el formulario para crear tu cuenta en el portal.',
                    style: AppTypography.bodyMd(
                        color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),

                  // --- Sección Datos personales ---
                  _SectionHeader(title: 'Datos personales'),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Nombres',
                    hint: 'Ej. Juan Carlos',
                    controller: _nombresCtrl,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Apellidos',
                    hint: 'Ej. Pérez García',
                    controller: _apellidosCtrl,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'DNI',
                    hint: '12345678',
                    controller: _dniCtrl,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length != 8) return 'DNI debe tener 8 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // --- Sección Contacto ---
                  _SectionHeader(title: 'Información de contacto'),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Correo electrónico',
                    hint: 'ejemplo@correo.com',
                    controller: _emailCtrl,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Teléfono / Celular',
                    hint: '999 999 999',
                    controller: _phoneCtrl,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 28),

                  // --- Sección Rol ---
                  _SectionHeader(title: 'Rol de usuario'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRol,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'estudiante',
                        child: Text('Estudiante'),
                      ),
                      DropdownMenuItem(
                        value: 'administrador',
                        child: Text('Administrador'),
                      ),
                      DropdownMenuItem(
                        value: 'director',
                        child: Text('Director'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedRol = v);
                      }
                    },
                  ),
                  const SizedBox(height: 28),

                  // --- Sección Seguridad ---
                  _SectionHeader(title: 'Seguridad'),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Contraseña',
                    hint: 'Mín. 8 caracteres',
                    controller: _passwordCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length < 8) return 'Mínimo 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirmar contraseña',
                    hint: 'Repite tu contraseña',
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v != _passwordCtrl.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- Términos ---
                  GestureDetector(
                    onTap: () =>
                        setState(() => _acceptTerms = !_acceptTerms),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _acceptTerms
                                ? AppColors.brandYellow
                                : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _acceptTerms
                                  ? AppColors.brandYellow
                                  : AppColors.outline,
                            ),
                          ),
                          child: _acceptTerms
                              ? const Icon(Icons.check,
                                  size: 14, color: AppColors.brandBlack)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Acepto los ',
                              style: AppTypography.labelLg(
                                  color: AppColors.onSurfaceVariant),
                              children: [
                                TextSpan(
                                  text: 'Términos y Condiciones',
                                  style: AppTypography.labelLg(
                                      color: AppColors.primary),
                                ),
                                TextSpan(
                                  text: ' del portal CEBA Go.',
                                  style: AppTypography.labelLg(
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- Botón ---
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => AppButton(
                      label: 'Registrarme',
                      loading: state is AuthLoading,
                      onPressed: () => _submit(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Ya tengo cuenta ---
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text.rich(
                        TextSpan(
                          text: '¿Ya tienes cuenta? ',
                          style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant),
                          children: [
                            TextSpan(
                              text: 'Inicia sesión',
                              style: AppTypography.labelLg(
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.brandYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: AppTypography.headlineMd(color: AppColors.onSurface)),
      ],
    );
  }
}
