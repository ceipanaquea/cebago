import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
                const SizedBox(height: 16),

                // Premium Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.brandBlack,
                  unselectedLabelColor: AppColors.outline,
                  indicatorColor: AppColors.brandYellow,
                  indicatorWeight: 3,
                  labelStyle: AppTypography.labelLg(),
                  tabs: const [
                    Tab(text: 'Pendientes'),
                    Tab(text: 'Aprobados'),
                    Tab(text: 'Observados'),
                  ],
                ),

                // Tab Content List
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsList(state.requests, 'Pendiente'),
                      _buildRequestsList(state.requests, 'Aprobado'),
                      _buildRequestsList(state.requests, 'Observado'),
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

  Widget _buildStatsGrid(AdminStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Pendientes', '${stats.pendingCount}', Colors.orange, Icons.hourglass_empty_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Aprobados', '${stats.approvedCount}', Colors.green, Icons.task_alt_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Observados', '${stats.observedCount}', AppColors.error, Icons.warning_amber_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Total Solicitudes', '${stats.totalRequests}', AppColors.outline, Icons.folder_open_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTypography.headlineMd(color: AppColors.onSurface)),
                  Text(label, style: AppTypography.labelXs(color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<AdminEnrollmentRequest> allRequests, String statusFilter) {
    final list = allRequests.where((r) => r.status == statusFilter).toList();

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
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        return _buildRequestCard(req);
      },
    );
  }

  Widget _buildRequestCard(AdminEnrollmentRequest req) {
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
              const SizedBox(width: 12),
              Text(
                req.id,
                style: AppTypography.labelSm(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'DNI: ${req.dni}  •  Enviado el ${req.date}',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
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
          if (req.status == 'Pendiente') ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text('Observar', style: AppTypography.labelSm(color: AppColors.error)),
                  onPressed: () {
                    context.read<AdminBloc>().add(RejectEnrollmentRequested(req.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Expediente ${req.id} observado.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('Aprobar Matrícula', style: AppTypography.labelSm(color: Colors.white)),
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

}
