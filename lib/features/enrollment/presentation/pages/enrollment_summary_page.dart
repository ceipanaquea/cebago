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

class EnrollmentSummaryPage extends StatelessWidget {
  const EnrollmentSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EnrollmentBloc, EnrollmentState>(
      listener: (context, state) {
        if (state is EnrollmentSuccessState) {
          context.pushReplacement(AppRoutes.enrollmentStatus, extra: state.enrollmentCode);
        } else if (state is EnrollmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! EnrollmentActiveState) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            ),
          );
        }

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
              'Resumen de Solicitud',
              style: AppTypography.headlineLg(color: AppColors.onSurface),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  'Datos Personales',
                  Icons.person_rounded,
                  [
                    _SummaryRow('Nombre completo', state.fullName),
                    _SummaryRow('DNI', state.dni),
                    _SummaryRow('Sexo', state.sex),
                    _SummaryRow('Fecha de nacimiento', state.birthDate),
                    _SummaryRow('Teléfono', state.phone),
                    _SummaryRow('Correo', state.email),
                    _SummaryRow('Dirección', state.address),
                    _SummaryRow('Edad', state.age),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  'Antecedentes Académicos',
                  Icons.school_outlined,
                  [
                    _SummaryRow('Ciclo solicitado', state.cycle),
                    _SummaryRow('Última institución', state.lastSchool),
                    _SummaryRow('Último grado', state.lastGradeCompleted),
                    _SummaryRow('Año de estudios', state.lastStudyYear),
                    _SummaryRow('Ausencia > 2 años', state.hasLongAbsence ? 'Sí' : 'No'),
                    if (state.hasLongAbsence)
                      _SummaryRow('Prueba de ubicación', state.requestsPlacementTest ? 'Solicitada' : 'No solicitada'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  'Opciones Especiales',
                  Icons.tune_rounded,
                  [
                    _SummaryRow('Modalidad', state.studyMode),
                    _SummaryRow('Exoneración Religión', state.requestsReligionExemption ? 'Sí' : 'No'),
                    _SummaryRow('Exoneración Ed. Física', state.requestsPEExemption ? 'Sí' : 'No'),
                    _SummaryRow('Discapacidad certificada', state.hasDisability ? 'Sí' : 'No'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  'Documentos',
                  Icons.folder_open_rounded,
                  state.documents.map((d) => _SummaryRow(d.name, d.isUploaded ? '✓ Subido' : '✗ Pendiente')).toList(),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Confirmar y Enviar Solicitud',
                  loading: state.isSubmitting,
                  onPressed: state.isSubmitting
                      ? null
                      : () {
                          context.read<EnrollmentBloc>().add(const SubmitEnrollment());
                        },
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Volver y Editar',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, IconData icon, List<_SummaryRow> rows) {
    return Container(
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
}

class _SummaryRow {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);
}
