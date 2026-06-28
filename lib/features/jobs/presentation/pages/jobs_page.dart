import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/jobs_bloc.dart';
import '../bloc/jobs_event.dart';
import '../bloc/jobs_state.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<JobsBloc>().add(const LoadJobsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          'Vacantes Disponibles',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<JobsBloc, JobsState>(
        builder: (context, state) {
          if (state is JobsInitial || state is JobsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            );
          }

          if (state is JobsLoaded) {
            return Column(
              children: [
                // --- Search and Filters Section ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            context.read<JobsBloc>().add(FilterJobsRequested(
                                  query: val,
                                  category: state.selectedCategory,
                                ));
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar ciclo, sede o taller...',
                            hintStyle: AppTypography.bodySm(color: AppColors.outline),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.outline),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: AppColors.outline),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<JobsBloc>().add(FilterJobsRequested(
                                            query: '',
                                            category: state.selectedCategory,
                                          ));
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter chips
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip('Todos', state),
                            const SizedBox(width: 8),
                            _buildFilterChip('Ciclo Inicial / Intermedio', state),
                            const SizedBox(width: 8),
                            _buildFilterChip('Ciclo Avanzado', state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Jobs List ---
                Expanded(
                  child: state.filteredJobs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = state.filteredJobs[index];
                            return _JobCard(
                              job: job,
                              onTap: () => _showJobDetailsBottomSheet(context, job),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is JobsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(state.message, style: AppTypography.bodyMd(color: AppColors.error), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Reintentar',
                      width: 150,
                      onPressed: () => context.read<JobsBloc>().add(const LoadJobsRequested()),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),

    );
  }

  Widget _buildFilterChip(String category, JobsLoaded state) {
    final isSelected = state.selectedCategory == category;
    return GestureDetector(
      onTap: () {
        context.read<JobsBloc>().add(FilterJobsRequested(
              query: _searchController.text,
              category: category,
            ));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlack : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? AppColors.brandBlack : AppColors.outlineVariant,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandBlack.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          category,
          style: AppTypography.labelSm(
            color: isSelected ? AppColors.brandYellow : AppColors.onSurfaceVariant,
          ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_off_outlined, color: AppColors.outline, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron vacantes',
              style: AppTypography.headlineMd(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustando los términos de búsqueda o los filtros.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showJobDetailsBottomSheet(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _JobDetailsBottomSheet(job: job);
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});
  final JobModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = job.availableVacancies == 0;
    final bool isCritical = job.availableVacancies > 0 && job.availableVacancies <= 5;
    
    Color statusColor = AppColors.primary;
    String statusText = 'Vacantes disponibles';
    
    if (isSoldOut) {
      statusColor = AppColors.error;
      statusText = 'Agotado';
    } else if (isCritical) {
      statusColor = Colors.orange;
      statusText = '¡Últimas ${job.availableVacancies} vacantes!';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Badge & Title)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getModeColor(job.mode).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        job.mode,
                        style: AppTypography.labelXs(color: _getModeColor(job.mode))
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (job.level == 'Ciclo Inicial / Intermedio' ? Colors.teal : Colors.deepPurple).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        job.level == 'Ciclo Inicial / Intermedio'
                            ? 'Ciclo Inicial / Intermedio (Primaria)'
                            : 'Ciclo Avanzado (Secundaria)',
                        style: AppTypography.labelXs(
                          color: job.level == 'Ciclo Inicial / Intermedio' ? Colors.teal[800] : Colors.deepPurple[800],
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        statusText,
                        style: AppTypography.labelXs(color: statusColor)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  job.title,
                  style: AppTypography.headlineMd(color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),

                // Location and Schedule rows
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.location,
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.schedule,
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Divider
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 16),

                // Progress Vacancies Indicator
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progreso de ocupación',
                                style: AppTypography.labelXs(color: AppColors.outline),
                              ),
                              Text(
                                '${job.totalVacancies - job.availableVacancies}/${job.totalVacancies} Cupos',
                                style: AppTypography.labelXs(color: AppColors.onSurfaceVariant)
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: isSoldOut ? 1.0 : (job.totalVacancies - job.availableVacancies) / job.totalVacancies,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceContainerLow,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSoldOut
                                    ? AppColors.error
                                    : isCritical
                                        ? Colors.orange
                                        : AppColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: AppColors.brandBlack, size: 20),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'Presencial':
        return const Color(0xFF765B00);
      case 'Semi-presencial':
        return Colors.indigo;
      case 'Distancia':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }
}

class _JobDetailsBottomSheet extends StatelessWidget {
  const _JobDetailsBottomSheet({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = job.availableVacancies == 0;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle indicator
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),

          // Content Area (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge & Title
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          job.mode,
                          style: AppTypography.labelSm(color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (job.level == 'Ciclo Inicial / Intermedio' ? Colors.teal : Colors.deepPurple).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          job.level == 'Ciclo Inicial / Intermedio'
                              ? 'Ciclo Inicial / Intermedio (Primaria)'
                              : 'Ciclo Avanzado (Secundaria)',
                          style: AppTypography.labelSm(
                            color: job.level == 'Ciclo Inicial / Intermedio' ? Colors.teal[800] : Colors.deepPurple[800],
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSoldOut ? AppColors.errorContainer : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          isSoldOut ? 'Sin vacantes' : '${job.availableVacancies} Vacantes disponibles',
                          style: AppTypography.labelSm(
                            color: isSoldOut ? AppColors.onErrorContainer : Colors.green[800],
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job.title,
                    style: AppTypography.headlineXl(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 20),

                  // Location and Schedule info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ubicación / Campus', style: AppTypography.labelSm(color: AppColors.outline)),
                                  const SizedBox(height: 2),
                                  Text(job.location, style: AppTypography.bodyMd(color: AppColors.onSurface)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.outlineVariant),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Horario y Turno', style: AppTypography.labelSm(color: AppColors.outline)),
                                  const SizedBox(height: 2),
                                  Text(job.schedule, style: AppTypography.bodyMd(color: AppColors.onSurface)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text('Detalles del Ciclo / Taller', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                  const SizedBox(height: 10),
                  Text(
                    job.description,
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Requirements
                  Text('Requisitos obligatorios', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                  const SizedBox(height: 12),
                  ...job.requirements.map((req) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                req,
                                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),

                  // Contact
                  Text('Contacto administrativo', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: AppColors.outline, size: 20),
                      const SizedBox(width: 10),
                      Text(job.contactEmail, style: AppTypography.bodyMd(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: isSoldOut ? 'Sin Vacantes Disponibles' : 'Postular / Matricularse',
                onPressed: isSoldOut
                    ? null
                    : () {
                        Navigator.pop(context); // Close bottom sheet
                        // Navegar a la pantalla de matricula llevando parámetros o inicializándola
                        context.push(AppRoutes.enrollment);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
