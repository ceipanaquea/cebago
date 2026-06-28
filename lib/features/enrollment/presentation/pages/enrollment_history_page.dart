import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_event.dart';
import '../bloc/enrollment_state.dart';

class EnrollmentHistoryPage extends StatefulWidget {
  const EnrollmentHistoryPage({super.key});

  @override
  State<EnrollmentHistoryPage> createState() => _EnrollmentHistoryPageState();
}

class _EnrollmentHistoryPageState extends State<EnrollmentHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<EnrollmentBloc>().add(const LoadEnrollmentHistory());
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
          'Historial Académico',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, state) {
          if (state is EnrollmentLoading || state is EnrollmentInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            );
          }

          if (state is EnrollmentHistoryLoadedState) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.history.length,
              itemBuilder: (context, index) {
                final hst = state.history[index];
                return _buildHistoryCard(hst);
              },
            );
          }

          if (state is EnrollmentError) {
            return Center(
              child: Text(state.message, style: AppTypography.bodyMd(color: AppColors.error)),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoricalEnrollment hst) {
    Color statusColor;
    switch (hst.status) {
      case 'Aprobado':
      case 'Finalizado':
        statusColor = Colors.green;
        break;
      case 'En Proceso':
        statusColor = Colors.orange;
        break;
      case 'Observado':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hst.year,
                    style: AppTypography.labelXs(color: AppColors.onSurfaceVariant)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    hst.status,
                    style: AppTypography.labelXs(color: statusColor).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hst.cycle,
              style: AppTypography.headlineMd(color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.outline),
                const SizedBox(width: 6),
                Text(
                  hst.date,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Observaciones y Notas:',
              style: AppTypography.labelSm(color: AppColors.outline),
            ),
            const SizedBox(height: 4),
            Text(
              hst.remarks,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
