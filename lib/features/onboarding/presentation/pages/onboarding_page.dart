import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      emoji: '🎓',
      title: 'Tu matrícula,\nrápida y fácil',
      description:
          'Realiza tu proceso de matrícula al CEBA desde tu celular, en cualquier momento y lugar.',
      color: AppColors.brandYellow,
    ),
    _OnboardingData(
      emoji: '📄',
      title: 'Sube tus\ndocumentos',
      description:
          'Adjunta tus documentos requeridos de forma segura directamente desde tu dispositivo.',
      color: Color(0xFFCACBCB),
    ),
    _OnboardingData(
      emoji: '📊',
      title: 'Sigue tu\nprogreso',
      description:
          'Consulta el estado de tu matrícula en tiempo real y recibe notificaciones importantes.',
      color: AppColors.surfaceContainerHigh,
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text('Omitir',
                    style: AppTypography.labelLg(
                        color: AppColors.onSurfaceVariant)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) =>
                    _OnboardingSlide(data: _pages[i]),
              ),
            ),

            // Dots + CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Comenzar ahora'
                        : 'Siguiente',
                    onPressed: _next,
                    icon: _currentPage == _pages.length - 1
                        ? null
                        : Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text.rich(TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Inicia sesión',
                          style: AppTypography.labelLg(
                              color: AppColors.primary),
                        ),
                      ],
                    )),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Ilustración
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineXl(color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
  final String emoji;
  final String title;
  final String description;
  final Color color;
}
