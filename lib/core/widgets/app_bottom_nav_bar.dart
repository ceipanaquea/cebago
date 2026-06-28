import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == UserRole.admin;
    
    final String location = GoRouterState.of(context).uri.toString();
    int activeIndex = 0;

    if (isAdmin) {
      if (location.startsWith(AppRoutes.home)) {
        activeIndex = 0;
      } else if (location.startsWith(AppRoutes.adminPanel)) activeIndex = 1;
      else if (location.startsWith(AppRoutes.adminVacancies)) activeIndex = 2;
      else if (location.startsWith(AppRoutes.adminReports)) activeIndex = 3;
      else if (location.startsWith(AppRoutes.profile)) activeIndex = 4;
    } else {
      if (location.startsWith(AppRoutes.home)) {
        activeIndex = 0;
      } else if (location.startsWith(AppRoutes.enrollment) || location.startsWith('/enrollment')) activeIndex = 1;
      else if (location.startsWith(AppRoutes.jobs)) activeIndex = 2;
      else if (location.startsWith(AppRoutes.profile)) activeIndex = 3;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: activeIndex,
        onTap: (i) {
          if (i == activeIndex) return;
          if (isAdmin) {
            if (i == 0) {
              context.go(AppRoutes.home);
            } else if (i == 1) context.go(AppRoutes.adminPanel);
            else if (i == 2) context.go(AppRoutes.adminVacancies);
            else if (i == 3) context.go(AppRoutes.adminReports);
            else if (i == 4) context.go(AppRoutes.profile);
          } else {
            if (i == 0) {
              context.go(AppRoutes.home);
            } else if (i == 1) context.go(AppRoutes.enrollment);
            else if (i == 2) context.go(AppRoutes.jobs);
            else if (i == 3) context.go(AppRoutes.profile);
          }
        },
        items: isAdmin 
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings_rounded), label: 'Panel'),
            BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work_rounded), label: 'Vacantes'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics_rounded), label: 'Reportes'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Perfil'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school_rounded), label: 'Matrícula'),
            BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work_rounded), label: 'Vacantes'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
      ),
    );
  }
}

