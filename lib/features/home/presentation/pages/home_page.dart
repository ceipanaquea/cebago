import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    context.read<HomeBloc>().add(HomeLoadRequested(userId: userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _HomeTab(),
    );
  }
}

// ---- HOME TAB ----
class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
            ),
          );
        }
        if (state is HomeLoaded) {
          final authState = context.read<AuthBloc>().state;
          final isAdmin = authState is AuthAuthenticated && authState.user.role == UserRole.admin;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<HomeBloc>().add(const HomeRefreshRequested());
            },
            child: CustomScrollView(
              slivers: [
                // --- AppBar ---
                SliverAppBar(
                  floating: true,
                  backgroundColor: AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('C',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: AppColors.brandBlack,
                              )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'CEBA',
                            style: AppTypography.headlineMd(color: AppColors.brandBlack)
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: 'Go',
                            style: AppTypography.headlineMd(color: AppColors.primary)
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  actions: [
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () => context.push(AppRoutes.notifications),
                          icon: const Icon(Icons.notifications_outlined,
                              color: AppColors.onSurface),
                        ),
                        if (state.unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${state.unreadNotifications}',
                                  style: AppTypography.labelXs(
                                      color: AppColors.onError),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(const AuthLogoutRequested());
                        context.go(AppRoutes.login);
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.onSurface),
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // --- Saludo ---
                        Text(
                          'Hola, ${state.userName} 👋',
                          style: AppTypography.headlineXl(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAdmin
                              ? 'Portal de administración escolar'
                              : 'Continúa con tu proceso de matrícula',
                          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),

                        // --- Status card ---
                        _StatusCard(state: state),
                        const SizedBox(height: 28),

                        // --- Accesos rápidos ---
                        Text('Accesos rápidos',
                            style: AppTypography.headlineMd(color: AppColors.onSurface)),
                        const SizedBox(height: 16),
                        _QuickAccessGrid(),
                        const SizedBox(height: 28),

                        // --- Pasos ---
                        if (!isAdmin) ...[
                          Text('Mis pasos',
                              style: AppTypography.headlineMd(color: AppColors.onSurface)),
                          const SizedBox(height: 16),
                          ...state.nextSteps
                              .asMap()
                              .entries
                              .map((e) => _StepTile(
                                  step: e.value, index: e.key + 1)),
                          const SizedBox(height: 28),
                        ],

                        // --- Anuncios ---
                        Text('Anuncios',
                            style: AppTypography.headlineMd(color: AppColors.onSurface)),
                        const SizedBox(height: 16),
                        ...state.announcements
                            .map((a) => _AnnouncementCard(announcement: a)),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == UserRole.admin;

    if (isAdmin) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.brandBlack,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlack.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Panel de Control',
                    style: AppTypography.labelLg(color: AppColors.outline)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Admin Activo',
                      style: AppTypography.labelSm(color: AppColors.brandYellow)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenido al portal de administración escolar.',
              style: AppTypography.headlineMd(color: AppColors.brandWhite),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa los accesos rápidos o la barra de navegación inferior para gestionar matrículas, vacantes y tickets de soporte.',
              style: AppTypography.bodySm(color: AppColors.outline),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandBlack,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlack.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estado de matrícula',
                  style: AppTypography.labelLg(color: AppColors.outline)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(state.enrollmentStatus,
                    style: AppTypography.labelSm(color: AppColors.brandYellow)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.35,
            backgroundColor: AppColors.onSurface.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 8),
          Text('35% completado',
              style: AppTypography.labelSm(color: AppColors.outline)),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: 'Docs. pendientes',
                value: '${state.pendingDocuments}',
                icon: Icons.file_copy_outlined,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Notificaciones',
                value: '${state.unreadNotifications}',
                icon: Icons.notifications_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.brandYellow),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: AppTypography.headlineMd(
                          color: AppColors.brandWhite)),
                  Text(label,
                      style: AppTypography.labelXs(color: AppColors.outline),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == UserRole.admin;

    final items = isAdmin
        ? const [
            _QA(icon: Icons.admin_panel_settings_rounded, label: 'Panel Admin', route: AppRoutes.adminPanel, color: Color(0xFFF4C542)),
            _QA(icon: Icons.analytics_rounded, label: 'Reportes', route: AppRoutes.adminReports, color: Color(0xFFCACBCB)),
            _QA(icon: Icons.chat_bubble_outline_rounded, label: 'Soporte', route: AppRoutes.support, color: Color(0xFFF4C542)),
            _QA(icon: Icons.settings_outlined, label: 'Ajustes', route: AppRoutes.settings, color: Color(0xFFCACBCB)),
          ]
        : const [
            _QA(icon: Icons.school_rounded, label: 'Matrícula', route: AppRoutes.enrollment, color: Color(0xFFF4C542)),
            _QA(icon: Icons.upload_file_rounded, label: 'Documentos', route: AppRoutes.uploadDocuments, color: Color(0xFFCACBCB)),
            _QA(icon: Icons.work_rounded, label: 'Vacantes', route: AppRoutes.jobs, color: Color(0xFFE5E2E1)),
            _QA(icon: Icons.history_rounded, label: 'Historial', route: AppRoutes.enrollmentHistory, color: Color(0xFFE2E2E2)),
            _QA(icon: Icons.chat_bubble_outline_rounded, label: 'Soporte', route: AppRoutes.support, color: Color(0xFFF4C542)),
            _QA(icon: Icons.settings_outlined, label: 'Ajustes', route: AppRoutes.settings, color: Color(0xFFCACBCB)),
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => context.push(item.route),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 22, color: AppColors.brandBlack),
                ),
                const SizedBox(height: 8),
                Text(item.label,
                    style: AppTypography.labelSm(color: AppColors.onSurface),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QA {
  const _QA({required this.icon, required this.label, required this.route, required this.color});
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.index});
  final HomeStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: step.isCompleted
            ? AppColors.primaryContainer.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step.isCompleted
              ? AppColors.primaryContainer.withValues(alpha: 0.4)
              : AppColors.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: step.isCompleted ? AppColors.brandYellow : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: step.isCompleted
                  ? const Icon(Icons.check_rounded, size: 20, color: AppColors.brandBlack)
                  : Text('$index',
                      style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: AppTypography.labelLg(
                        color: step.isCompleted
                            ? AppColors.primary
                            : AppColors.onSurface)),
                Text(step.description,
                    style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (!step.isCompleted)
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.outline, size: 20),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});
  final HomeAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcement.isNew)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: const BoxDecoration(
                color: AppColors.brandYellow,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(announcement.title,
                    style: AppTypography.labelLg(color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text(announcement.body,
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
