import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const LoadNotificationsRequested());
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
          'Bandeja de Entrada',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.notifications.isNotEmpty) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationsBloc>().add(const ClearAllRequested());
                  },
                  child: Text(
                    'Limpiar',
                    style: AppTypography.labelLg(color: AppColors.error),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          )
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            );
          }

          if (state is NotificationsLoaded) {
            final list = state.notifications;
            if (list.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final notif = list[index];
                return _NotificationItem(
                  notif: notif,
                  onTap: () {
                    if (!notif.isRead) {
                      context.read<NotificationsBloc>().add(MarkAsReadRequested(notif.id));
                    }
                  },
                );
              },
            );
          }

          if (state is NotificationsError) {
            return Center(
              child: Text(state.message, style: AppTypography.bodyMd(color: AppColors.error)),
            );
          }

          return const SizedBox.shrink();
        },
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
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.outline, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Bandeja vacía',
              style: AppTypography.headlineMd(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes notificaciones o mensajes académicos pendientes en este momento.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.notif, required this.onTap});
  final NotificationModel notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData leadingIcon;
    Color leadingColor;

    switch (notif.category) {
      case 'matricula':
        leadingIcon = Icons.school_rounded;
        leadingColor = AppColors.brandYellow;
        break;
      case 'taller':
        leadingIcon = Icons.star_outline_rounded;
        leadingColor = Colors.teal;
        break;
      case 'general':
      default:
        leadingIcon = Icons.info_outline_rounded;
        leadingColor = AppColors.outline;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.surfaceContainerLowest : AppColors.brandYellow.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? AppColors.outlineVariant : AppColors.brandYellow.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: leadingColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(leadingIcon, color: leadingColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: AppTypography.labelLg(color: AppColors.onSurface)
                              .copyWith(fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notif.timestamp,
                        style: AppTypography.labelXs(color: AppColors.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.body,
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.brandYellow,
                  shape: BoxShape.circle,
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
