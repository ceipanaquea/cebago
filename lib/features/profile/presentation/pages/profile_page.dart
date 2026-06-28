import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfileRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final title = state is ProfileLoaded && state.isAdmin ? 'Mi Perfil' : 'Mi Perfil Estudiantil';
            return Text(
              title,
              style: AppTypography.headlineLg(color: AppColors.onSurface),
            );
          },
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            );
          }

          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Avatar Header Card
                  _buildAvatarCard(state),
                  const SizedBox(height: 24),

                  // Academic Metrics Grid
                  if (!state.isAdmin) ...[
                    _buildMetricsGrid(state),
                    const SizedBox(height: 28),
                  ],

                  // Contact Details Section
                  _buildContactDetails(state),
                  const SizedBox(height: 28),

                  // Gateway to Admin Panel if user is Admin
                  if (state.isAdmin) ...[
                    _buildAdminPanelGateway(context),
                    const SizedBox(height: 20),
                  ],

                  // Logout & Actions Button
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          if (state is ProfileError) {
            return Center(
              child: Text(state.message, style: AppTypography.bodyMd(color: AppColors.error)),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAvatarCard(ProfileLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.brandBlack,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlack.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandWhite.withValues(alpha: 0.2), width: 3),
                ),
                child: Center(
                  child: Text(
                    state.fullName.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.fullName,
                      style: AppTypography.headlineMd(color: AppColors.brandWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isAdmin
                          ? 'Correo: ${state.email}'
                          : 'Código: ${state.studentId}',
                      style: AppTypography.labelSm(color: AppColors.outline),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        state.isAdmin ? 'Personal Administrativo' : 'Estudiante Activo',
                        style: AppTypography.labelXs(color: AppColors.brandYellow),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          if (!state.isAdmin) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Colors.white10),
            ),
            Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.brandYellow, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.currentCycle,
                    style: AppTypography.bodySm(color: AppColors.brandWhite.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ProfileLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desempeño Académico',
          style: AppTypography.headlineMd(color: AppColors.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMetricItem(
              icon: Icons.calendar_today_rounded,
              label: 'Asistencia General',
              value: state.attendanceRate,
              iconColor: Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildMetricItem(
              icon: Icons.stars_rounded,
              label: 'Promedio de Notas',
              value: state.academicAverages,
              iconColor: AppColors.brandYellow,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTypography.headlineMd(color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.labelXs(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactDetails(ProfileLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Información de Contacto', style: AppTypography.headlineMd(color: AppColors.onSurface)),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                onPressed: () => _showEditContactDialog(context, state),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email_outlined, 'Correo electrónico', state.email),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.outlineVariant),
          ),
          _buildInfoRow(Icons.phone_android_rounded, 'Número de celular', state.phone),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.outlineVariant),
          ),
          _buildInfoRow(Icons.location_on_outlined, 'Dirección domiciliaria', state.address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.outline, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelXs(color: AppColors.outline)),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodyMd(color: AppColors.onSurface)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAdminPanelGateway(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlack,
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.brandYellow, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel Administrativo',
                  style: AppTypography.headlineMd(color: AppColors.brandWhite),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión de vacantes, matrículas de alumnos e informes generales.',
                  style: AppTypography.bodySm(color: AppColors.brandWhite.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.brandBlack,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => context.push(AppRoutes.adminPanel),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'Cerrar Sesión Estudiantil',
          variant: AppButtonVariant.outlined,
          onPressed: () {
            context.read<AuthBloc>().add(const AuthLogoutRequested());
            context.go(AppRoutes.login);
          },
        ),
      ],
    );
  }

  void _showEditContactDialog(BuildContext context, ProfileLoaded state) {
    final emailCtrl = TextEditingController(text: state.email);
    final phoneCtrl = TextEditingController(text: state.phone);
    final addressCtrl = TextEditingController(text: state.address);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Editar Información', style: AppTypography.headlineMd(color: AppColors.onSurface)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Correo electrónico', controller: emailCtrl, prefixIcon: Icons.email_outlined),
                const SizedBox(height: 16),
                AppTextField(label: 'Número de celular', controller: phoneCtrl, prefixIcon: Icons.phone_android_rounded),
                const SizedBox(height: 16),
                AppTextField(label: 'Dirección domiciliaria', controller: addressCtrl, prefixIcon: Icons.location_on_outlined),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: AppTypography.labelLg(color: AppColors.outline)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.brandBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                this.context.read<ProfileBloc>().add(UpdateDetailsRequested(
                      email: emailCtrl.text,
                      phone: phoneCtrl.text,
                      address: addressCtrl.text,
                    ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Datos de contacto actualizados correctamente!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Guardar', style: AppTypography.labelLg(color: AppColors.brandBlack)),
            ),
          ],
        );
      },
    );
  }
}
