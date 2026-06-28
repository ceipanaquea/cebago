import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class EnrollmentStatusPage extends StatelessWidget {
  const EnrollmentStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el código de matrícula generado a través del parámetro extra de GoRouter
    final enrollmentCode = GoRouterState.of(context).extra as String? ?? 'MAT-2026-4839';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Success Visuals with micro-animation vibes
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                '¡Solicitud Recibida!',
                style: AppTypography.headlineXl(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu expediente de matrícula ha sido enviado exitosamente al área académica.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Ticket/Receipt view of Enrollment
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Código de Matrícula', style: AppTypography.labelSm(color: AppColors.outline)),
                        Text('Fecha de Envío', style: AppTypography.labelSm(color: AppColors.outline)),
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
                          '26 May, 2026',
                          style: AppTypography.labelLg(color: AppColors.onSurface),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: AppColors.outlineVariant),
                    ),

                    // Process Tracking Checklist
                    _buildProcessStep(
                      icon: Icons.check_circle_rounded,
                      iconColor: Colors.green,
                      title: 'Expediente Enviado',
                      subtitle: 'Documentos e información cargada exitosamente.',
                      isDone: true,
                    ),
                    _buildProcessStep(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: Colors.orange,
                      title: 'Validación de Documentos',
                      subtitle: 'El comité revisará la validez de tus certificados. (24-48 horas)',
                      isDone: false,
                      showConnectorLine: true,
                    ),
                    _buildProcessStep(
                      icon: Icons.mail_outline_rounded,
                      iconColor: AppColors.outline,
                      title: 'Generación de Credenciales',
                      subtitle: 'Recibirás un correo con tus accesos a la plataforma virtual.',
                      isDone: false,
                      showConnectorLine: true,
                    ),
                    _buildProcessStep(
                      icon: Icons.school_outlined,
                      iconColor: AppColors.outline,
                      title: 'Inducción de Bienvenida',
                      subtitle: '¡Listo para iniciar tus clases y talleres técnicos!',
                      isDone: false,
                      showConnectorLine: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Action buttons
              AppButton(
                label: 'Ir a la Pantalla de Inicio',
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Ver mi Historial de Matrícula',
                variant: AppButtonVariant.outlined,
                onPressed: () => context.push(AppRoutes.enrollmentHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDone,
    bool showConnectorLine = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone ? Colors.green : AppColors.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLg(color: AppColors.onSurface)
                        .copyWith(fontWeight: isDone ? FontWeight.w800 : FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
