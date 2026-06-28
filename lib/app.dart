import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/jobs/presentation/bloc/jobs_bloc.dart';
import 'features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/support/presentation/bloc/support_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(),
        ),
        BlocProvider<JobsBloc>(
          create: (context) => JobsBloc(),
        ),
        BlocProvider<EnrollmentBloc>(
          create: (context) => EnrollmentBloc(),
        ),
        BlocProvider<NotificationsBloc>(
          create: (context) => NotificationsBloc(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(),
        ),
        BlocProvider<AdminBloc>(
          create: (context) => AdminBloc(),
        ),
        BlocProvider<SupportBloc>(
          create: (context) => SupportBloc(),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'CEBA Go',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Ajustes usarán light por defecto
        routerConfig: AppRouter.router,
      ),
    );
  }
}
