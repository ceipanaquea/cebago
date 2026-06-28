import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = LogoSize.medium,
    this.showTagline = false,
  });

  final LogoSize size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final double iconSize;
    final double fontSize;

    switch (size) {
      case LogoSize.small:
        iconSize = 32;
        fontSize = 20;
        break;
      case LogoSize.medium:
        iconSize = 48;
        fontSize = 28;
        break;
      case LogoSize.large:
        iconSize = 72;
        fontSize = 40;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize * 1.5,
          height: iconSize * 1.5,
          decoration: BoxDecoration(
            color: AppColors.brandYellow,
            borderRadius: BorderRadius.circular(iconSize * 0.35),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandYellow.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'C',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: iconSize * 0.75,
                fontWeight: FontWeight.w800,
                color: AppColors.brandBlack,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'CEBA',
                style: AppTypography.headlineLg(color: AppColors.brandBlack)
                    .copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Go',
                style: AppTypography.headlineLg(color: AppColors.primary)
                    .copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Portal de Matrícula',
            style: AppTypography.labelLg(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

enum LogoSize { small, medium, large }
