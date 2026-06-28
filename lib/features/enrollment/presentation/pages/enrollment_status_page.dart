import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_event.dart';
import '../bloc/enrollment_state.dart';

class EnrollmentStatusPage extends StatefulWidget {
  const EnrollmentStatusPage({super.key});

  @override
  State<EnrollmentStatusPage> createState() => _EnrollmentStatusPageState();
}

class _EnrollmentStatusPageState extends State<EnrollmentStatusPage> {
  @override
  void initState() {
    super.initState();
    context.read<EnrollmentBloc>().add(const LoadEnrollmentDetails());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, state) {
        if (state is EnrollmentInitial || state is EnrollmentLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            ),
          );
        }

        if (state is! EnrollmentActiveState) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'No se encontró matrícula activa.',
                style: AppTypography.bodyMd(color: AppColors.onSurface),
              ),
            ),
          );
        }

        final status = state.enrollmentStatus;
        final enrollmentCode = state.dni.isNotEmpty ? 'MAT-2026-${state.dni.substring(state.dni.length - 4)}' : 'MAT-2026-4839';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Success Icon / Status Icon
                  _buildStatusHeaderIcon(status),
                  const SizedBox(height: 24),

                  Text(
                    'Estado de Matrícula',
                    style: AppTypography.headlineXl(color: AppColors.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí puedes hacer el seguimiento del estado de tu expediente académico.',
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Real-time Status Chip
                  _buildStatusChip(status),
                  const SizedBox(height: 28),

                  // Ticket Card detailing the Enrollment
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Código de Matrícula', style: AppTypography.labelSm(color: AppColors.outline)),
                            Text('Ciclo de Ingreso', style: AppTypography.labelSm(color: AppColors.outline)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              enrollmentCode,
                              style: AppTypography.headlineMd(color: AppColors.primary)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              state.cycle,
                              style: AppTypography.labelLg(color: AppColors.onSurface),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: AppColors.outlineVariant),
                        ),

                        // Real-time observations if present
                        if (state.observations.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Observaciones de Administración:',
                                      style: AppTypography.labelLg(color: AppColors.error),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.observations,
                                  style: AppTypography.bodySm(color: AppColors.onSurface),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: AppColors.outlineVariant),
                          ),
                        ],

                        // Document submission status checklist
                        Text(
                          'Verificación de Documentos',
                          style: AppTypography.headlineMd(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 12),
                        ...state.documents.map((doc) => _buildDocumentStatusRow(doc)),
                      ],
                    ),
                  ),

                  // Premium Certificate section if approved
                  if (status == 'Aprobado') ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brandBlack, Color(0xFF2A2A2A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: AppColors.brandYellow, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Matrícula Aprobada',
                                      style: AppTypography.headlineMd(color: AppColors.brandWhite),
                                    ),
                                    Text(
                                      'Tu constancia digital está lista.',
                                      style: AppTypography.bodySm(color: AppColors.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Ver Constancia de Matrícula',
                            icon: Icons.download_rounded,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Descargando constancia digital... (próximamente disponible).'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Action buttons
                  AppButton(
                    label: 'Ir a la Pantalla de Inicio',
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Editar Ficha de Matrícula',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => context.push(AppRoutes.enrollment),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeaderIcon(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Aprobado':
        color = Colors.green;
        icon = Icons.verified_rounded;
        break;
      case 'Observado':
        color = AppColors.brandYellow;
        icon = Icons.warning_rounded;
        break;
      case 'Rechazado':
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      case 'En Revisión':
        color = Colors.blue;
        icon = Icons.search_rounded;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 4),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg, fg;
    IconData icon;
    switch (status) {
      case 'Aprobado':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        break;
      case 'En Revisión':
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue.shade800;
        icon = Icons.search_rounded;
        break;
      case 'Observado':
        bg = AppColors.primaryContainer.withValues(alpha: 0.2);
        fg = AppColors.primary;
        icon = Icons.warning_amber_rounded;
        break;
      case 'Rechazado':
        bg = AppColors.errorContainer.withValues(alpha: 0.4);
        fg = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = Colors.orange.withValues(alpha: 0.12);
        fg = Colors.orange.shade800;
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Text(
            status,
            style: AppTypography.labelLg(color: fg).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusRow(RequiredDocument doc) {
    Color statusColor = AppColors.outline;
    IconData leadingIcon = Icons.hourglass_empty_rounded;

    if (doc.isUploaded) {
      statusColor = Colors.green;
      leadingIcon = Icons.check_circle_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(leadingIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              doc.name,
              style: AppTypography.bodySm(color: AppColors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            doc.isUploaded ? 'Subido' : 'Pendiente',
            style: AppTypography.labelSm(color: statusColor),
          ),
        ],
      ),
    );
  }
}
