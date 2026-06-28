import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<AdminBloc>().add(const LoadAdminDataRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: Text(
          'Consola de Administración',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.adminReports),
          )
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            );
          }

          if (state is AdminLoaded) {
            return Column(
              children: [
                // Stats Grid
                _buildStatsGrid(state.stats),
                const SizedBox(height: 8),

                // Mode Filter Row
                _buildFilterRow(context, state),
                const SizedBox(height: 8),

                // Premium Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.brandBlack,
                  unselectedLabelColor: AppColors.outline,
                  indicatorColor: AppColors.brandYellow,
                  indicatorWeight: 3,
                  labelStyle: AppTypography.labelLg(),
                  tabs: const [
                    Tab(text: 'Pendientes'),
                    Tab(text: 'En Revisión'),
                    Tab(text: 'Aprobados'),
                    Tab(text: 'Observados'),
                    Tab(text: 'Rechazados'),
                  ],
                ),

                // Tab Content List
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsList(state, 'Pendiente'),
                      _buildRequestsList(state, 'En Revisión'),
                      _buildRequestsList(state, 'Aprobado'),
                      _buildRequestsList(state, 'Observado'),
                      _buildRequestsList(state, 'Rechazado'),
                    ],
                  ),
                ),
              ],
            );
          }

          if (state is AdminError) {
            return Center(
              child: Text(state.message, style: AppTypography.bodyMd(color: AppColors.error)),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, AdminLoaded state) {
    final activeMode = state.activeModeFilter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          for (final mode in ['Todos', 'Presencial', 'Semi-presencial', 'A Distancia'])
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(mode),
                selected: mode == 'Todos' ? activeMode.isEmpty : activeMode == mode,
                selectedColor: AppColors.primaryContainer.withValues(alpha: 0.4),
                checkmarkColor: AppColors.primary,
                labelStyle: AppTypography.labelSm(
                  color: (mode == 'Todos' ? activeMode.isEmpty : activeMode == mode)
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                onSelected: (_) {
                  context.read<AdminBloc>().add(
                        FilterEnrollmentsRequested(
                          status: state.activeStatusFilter,
                          mode: mode == 'Todos' ? '' : mode,
                        ),
                      );
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Pendientes', '${stats.pendingCount}', Colors.orange, Icons.hourglass_empty_rounded),
              const SizedBox(width: 8),
              _buildStatCard('En Revisión', '${stats.underReviewCount}', Colors.blue, Icons.search_rounded),
              const SizedBox(width: 8),
              _buildStatCard('Aprobados', '${stats.approvedCount}', Colors.green, Icons.task_alt_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('Observados', '${stats.observedCount}', AppColors.primary, Icons.warning_amber_rounded),
              const SizedBox(width: 8),
              _buildStatCard('Rechazados', '${stats.rejectedCount}', AppColors.error, Icons.cancel_rounded),
              const SizedBox(width: 8),
              _buildStatCard('Total', '${stats.totalRequests}', AppColors.outline, Icons.folder_open_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTypography.headlineMd(color: AppColors.onSurface).copyWith(fontSize: 16)),
                  Text(label, style: AppTypography.labelXs(color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(AdminLoaded state, String statusFilter) {
    var list = state.requests.where((r) => r.status == statusFilter).toList();
    if (state.activeModeFilter.isNotEmpty) {
      list = list.where((r) => r.studyMode == state.activeModeFilter).toList();
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, color: AppColors.outline, size: 40),
            const SizedBox(height: 12),
            Text(
              'No hay registros en esta sección',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        return _buildRequestCard(req);
      },
    );
  }

  Widget _buildRequestCard(AdminEnrollmentRequest req) {
    final showActions = req.status == 'Pendiente' || req.status == 'En Revisión';
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
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/admin/student/${req.matriculaId}', extra: req),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        req.studentName,
                        style: AppTypography.headlineMd(color: AppColors.onSurface).copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${req.id}  •  DNI: ${req.dni}  •  Modalidad: ${req.studyMode}',
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enviado el ${req.date}',
                  style: AppTypography.bodySm(color: AppColors.outline),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.school_rounded, size: 16, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req.cycle,
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (req.status == 'Pendiente')
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: Text('Revisar', style: AppTypography.labelSm(color: Colors.blue)),
                    onPressed: () {
                      context.read<AdminBloc>().add(MarkUnderReviewRequested(
                            matriculaId: req.matriculaId,
                            perfilId: req.perfilId,
                            ticketCode: req.id,
                          ));
                    },
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text('Observar', style: AppTypography.labelSm(color: AppColors.primary)),
                  onPressed: () => _showObservationDialog(context, req),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text('Aprobar', style: AppTypography.labelSm(color: Colors.white)),
                  onPressed: () {
                    context.read<AdminBloc>().add(ApproveEnrollmentRequested(req.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Expediente aprobado correctamente!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ],
      ),
    );
  }

  void _showObservationDialog(BuildContext context, AdminEnrollmentRequest req) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Agregar Observación', style: AppTypography.headlineMd(color: AppColors.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El estudiante recibirá una notificación solicitando correcciones en su trámite.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Detalles de Observación',
              hint: 'Ej. Copia de DNI borrosa, subir nuevamente.',
              controller: controller,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<AdminBloc>().add(AddObservationRequested(
                      matriculaId: req.matriculaId,
                      perfilId: req.perfilId,
                      ticketCode: req.id,
                      observationText: controller.text.trim(),
                    ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expediente ${req.id} observado.'),
                    backgroundColor: AppColors.brandBlack,
                  ),
                );
              }
            },
            child: Text('Enviar', style: AppTypography.labelLg(color: AppColors.brandWhite)),
          ),
        ],
      ),
    );
  }
}
