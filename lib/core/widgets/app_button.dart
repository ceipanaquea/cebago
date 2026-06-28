import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    Color bgColor;
    Color fgColor;
    Color? borderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = isDisabled
            ? AppColors.primaryContainer.withValues(alpha: 0.5)
            : AppColors.brandYellow;
        fgColor = AppColors.brandBlack;
        break;
      case AppButtonVariant.secondary:
        bgColor = isDisabled
            ? AppColors.brandBlack.withValues(alpha: 0.5)
            : AppColors.brandBlack;
        fgColor = AppColors.brandWhite;
        break;
      case AppButtonVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = AppColors.onSurface;
        borderColor = AppColors.outline;
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        break;
    }

    Widget child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.buttonText(color: fgColor)),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : null,
          boxShadow: variant == AppButtonVariant.primary && !isDisabled
              ? [
                  BoxShadow(
                    color: AppColors.brandYellow.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(8),
            splashColor: fgColor.withValues(alpha: 0.1),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, outlined, ghost }
