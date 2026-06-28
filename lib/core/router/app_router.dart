import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_scaffold.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/jobs/presentation/pages/jobs_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_summary_page.dart';
import '../../features/enrollment/presentation/pages/upload_documents_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_status_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_history_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/admin/presentation/pages/admin_panel_page.dart';
import '../../features/admin/presentation/pages/admin_student_detail_page.dart';
import '../../features/admin/presentation/pages/admin_vacancies_page.dart';
import '../../features/admin/presentation/pages/admin_reports_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String jobs = '/jobs';
  static const String enrollment = '/enrollment';
  static const String enrollmentSummary = '/enrollment/summary';
  static const String uploadDocuments = '/enrollment/upload';
  static const String enrollmentStatus = '/enrollment/status';
  static const String enrollmentHistory = '/enrollment/history';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String adminPanel = '/admin';
  static const String adminStudentDetail = '/admin/student/:id';
  static const String adminVacancies = '/admin-vacancies';
  static const String adminReports = '/admin/reports';
  static const String support = '/support';
  static const String settings = '/settings';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildPage(state, const SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPage(state, const OnboardingPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPage(state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => _buildPage(state, const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) => _buildPage(state, const ForgotPasswordPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => _buildPage(state, const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.jobs,
            name: 'jobs',
            pageBuilder: (context, state) => _buildPage(state, const JobsPage()),
          ),
          GoRoute(
            path: AppRoutes.enrollment,
            name: 'enrollment',
            pageBuilder: (context, state) => _buildPage(state, const EnrollmentPage()),
          ),
          GoRoute(
            path: AppRoutes.enrollmentSummary,
            name: 'enrollmentSummary',
            pageBuilder: (context, state) => _buildPage(state, const EnrollmentSummaryPage()),
          ),
          GoRoute(
            path: AppRoutes.uploadDocuments,
            name: 'uploadDocuments',
            pageBuilder: (context, state) => _buildPage(state, const UploadDocumentsPage()),
          ),
          GoRoute(
            path: AppRoutes.enrollmentStatus,
            name: 'enrollmentStatus',
            pageBuilder: (context, state) => _buildPage(state, const EnrollmentStatusPage()),
          ),
          GoRoute(
            path: AppRoutes.enrollmentHistory,
            name: 'enrollmentHistory',
            pageBuilder: (context, state) => _buildPage(state, const EnrollmentHistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            pageBuilder: (context, state) => _buildPage(state, const NotificationsPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => _buildPage(state, const ProfilePage()),
          ),
          GoRoute(
            path: AppRoutes.adminPanel,
            name: 'adminPanel',
            pageBuilder: (context, state) => _buildPage(state, const AdminPanelPage()),
          ),
          GoRoute(
            path: '/admin/student/:id',
            name: 'adminStudentDetail',
            pageBuilder: (context, state) {
              final req = state.extra as dynamic;
              return _buildPage(state, AdminStudentDetailPage(request: req));
            },
          ),
          GoRoute(
            path: AppRoutes.adminVacancies,
            name: 'adminVacancies',
            pageBuilder: (context, state) => _buildPage(state, const AdminVacanciesPage()),
          ),
          GoRoute(
            path: AppRoutes.adminReports,
            name: 'adminReports',
            pageBuilder: (context, state) => _buildPage(state, const AdminReportsPage()),
          ),
          GoRoute(
            path: AppRoutes.support,
            name: 'support',
            pageBuilder: (context, state) => _buildPage(state, const SupportPage()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => _buildPage(state, const SettingsPage()),
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => _buildPage(
      state,
      Scaffold(
        body: Center(
          child: Text('Página no encontrada: ${state.error}'),
        ),
      ),
    ),
  );

  static CustomTransitionPage _buildPage(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
