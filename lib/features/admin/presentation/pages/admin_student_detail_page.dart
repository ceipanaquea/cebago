import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminStudentDetailPage extends StatelessWidget {
  final AdminEnrollmentRequest? request;

  const AdminStudentDetailPage({super.key, this.request});

  @override
  Widget build(BuildContext context) {
    // If not supplied directly via parameter, extract it from router state
    final req = request ?? GoRouterState.of(context).extra as AdminEnrollmentRequest?;
    if (req == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Text(
            'Expediente no encontrado.',
            style: AppTypography.bodyMd(color: AppColors.error),
          ),
        ),
      );
    }

    final isEditable = req.status == 'Pendiente' || req.status == 'En Revisión';

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
          'Detalles de Matrícula',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Card Header
            _buildStudentHeaderCard(context, req),
            const SizedBox(height: 20),

            // Section 1: Datos Personales
            _buildDetailSection(
              'Datos Personales',
              Icons.person_rounded,
              [
                _DetailRow('DNI', req.dni),
                _DetailRow('Teléfono Celular', req.phone),
                _DetailRow('Correo de Contacto', req.email),
              ],
            ),
            const SizedBox(height: 16),

            // Section 2: Datos Académicos
            _buildDetailSection(
              'Datos Académicos',
              Icons.school_outlined,
              [
                _DetailRow('Ciclo Solicitado', req.cycle),
                _DetailRow('Modalidad de Estudio', req.studyMode),
                _DetailRow('Prueba de Ubicación', req.requestsPlacementTest ? 'Solicitada' : 'No Solicitada'),
              ],
            ),
            const SizedBox(height: 16),

            // Section 3: Documentos Subidos
            _buildDetailSection(
              'Documentos Enviados',
              Icons.folder_open_rounded,
              [
                _DetailRow('DNI (Copia)', req.urlDni.isNotEmpty ? 'Enviado ✓' : 'Falta ✗'),
                _DetailRow('Foto Carnet', req.urlPhoto.isNotEmpty ? 'Enviado ✓' : 'Falta ✗'),
                _DetailRow('Certificado de Estudios', req.urlCert.isNotEmpty ? 'Enviado ✓' : 'Falta ✗'),
                if (req.hasDisability)
                  _DetailRow('Doc. de Discapacidad', req.urlDisabilityDoc.isNotEmpty ? 'Enviado ✓' : 'Falta ✗'),
              ],
            ),

            // Observations section if present
            if (req.observations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                'Observaciones Previas',
                Icons.warning_amber_rounded,
                [
                  _DetailRow('Observaciones', req.observations),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Gated Action Buttons
            if (isEditable) ...[
              if (req.status == 'Pendiente') ...[
                AppButton(
                  label: 'Iniciar Revisión de Expediente',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.search_rounded,
                  onPressed: () {
                    context.read<AdminBloc>().add(MarkUnderReviewRequested(
                          matriculaId: req.matriculaId,
                          perfilId: req.perfilId,
                          ticketCode: req.id,
                        ));
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Expediente ${req.id} en revisión.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              AppButton(
                label: 'Aprobar Matrícula',
                variant: AppButtonVariant.secondary,
                icon: Icons.check_circle_outline_rounded,
                onPressed: () {
                  context.read<AdminBloc>().add(ApproveEnrollmentRequested(req.id));
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Expediente aprobado correctamente!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Observar / Solicitar Corrección',
                icon: Icons.edit_note_rounded,
                onPressed: () => _showObservationDialog(context, req),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Rechazar Solicitud Directamente',
                icon: Icons.cancel_rounded,
                onPressed: () => _showRejectDialog(context, req),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeaderCard(BuildContext context, AdminEnrollmentRequest req) {
    Color statusColor;
    switch (req.status) {
      case 'Aprobado':
        statusColor = Colors.green;
        break;
      case 'En Revisión':
        statusColor = Colors.blue;
        break;
      case 'Observado':
        statusColor = AppColors.primary;
        break;
      case 'Rechazado':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandBlack,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  req.status,
                  style: AppTypography.labelXs(color: statusColor).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                req.id,
                style: AppTypography.labelLg(color: AppColors.brandYellow).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            req.studentName,
            style: AppTypography.headlineXl(color: AppColors.brandWhite),
          ),
          const SizedBox(height: 6),
          Text(
            'Código de Matrícula: ${req.matriculaId}',
            style: AppTypography.bodySm(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<_DetailRow> rows) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTypography.headlineMd(color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(r.label, style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: Text(
                        r.value.isEmpty ? '—' : r.value,
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
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
              'El estudiante recibirá una notificación solicitando correcciones.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Observación',
              hint: 'Ej. Adjunte una foto tamaño carnet más clara.',
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
                context.pop();
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

  void _showRejectDialog(BuildContext context, AdminEnrollmentRequest req) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rechazar Solicitud', style: AppTypography.headlineMd(color: AppColors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta acción es definitiva. El expediente cambiará a estado Rechazado.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Motivo del Rechazo',
              hint: 'Ej. No cumple con la edad mínima reglamentaria.',
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
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<AdminBloc>().add(RejectEnrollmentDirectlyRequested(
                      matriculaId: req.matriculaId,
                      perfilId: req.perfilId,
                      ticketCode: req.id,
                      reason: controller.text.trim(),
                    ));
                Navigator.pop(ctx);
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expediente ${req.id} rechazado definitivamente.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text('Rechazar', style: AppTypography.labelLg(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}
