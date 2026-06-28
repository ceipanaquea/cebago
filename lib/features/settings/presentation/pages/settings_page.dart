import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const LoadSettingsRequested());
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
        title: Text(
          'Configuración',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading || state is SettingsInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            );
          }

          if (state is SettingsLoaded) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Preferences Section
                _buildSectionHeader('Preferencias del Sistema'),
                const SizedBox(height: 10),
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notificaciones Push',
                  subtitle: 'Recibir alertas de vacantes e inscripciones',
                  value: state.isNotificationsEnabled,
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(const ToggleNotificationsRequested());
                  },
                ),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Modo Oscuro',
                  subtitle: 'Reducir fatiga visual en la noche',
                  value: state.isDarkMode,
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(const ToggleDarkModeRequested());
                  },
                ),
                const SizedBox(height: 28),

                // Security Section
                _buildSectionHeader('Privacidad y Seguridad'),
                const SizedBox(height: 10),
                _buildSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Ingreso Biométrico',
                  subtitle: 'Iniciar sesión usando Dactilar o Facial',
                  value: state.isBiometricsEnabled,
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(const ToggleBiometricsRequested());
                  },
                ),
                const SizedBox(height: 12),
                _buildClickableTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Cambiar Contraseña',
                  subtitle: 'Actualizar tu clave de acceso estudiantil',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función disponible en servidores de producción.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Info & Legal Section
                _buildSectionHeader('Información y Soporte'),
                const SizedBox(height: 10),
                _buildClickableTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y Condiciones',
                  subtitle: 'Normativa interna académica de CEBA Go',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildClickableTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Políticas de Privacidad',
                  subtitle: 'Tratamiento de datos personales',
                  onTap: () {},
                ),
                const SizedBox(height: 32),

                // Version logo
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: AppColors.outline, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'CEBA Go v1.0.0 (Edición Emprendedor)',
                        style: AppTypography.labelXs(color: AppColors.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2026 Ministerio de Educación / CEBA Inc.',
                        style: AppTypography.labelXs(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: AppTypography.headlineMd(color: AppColors.onSurfaceVariant).copyWith(fontSize: 16),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLg(color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.brandYellow,
            activeTrackColor: AppColors.brandYellow.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.labelLg(color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
