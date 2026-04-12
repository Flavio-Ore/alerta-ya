import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';

enum SeverityLevel { low, moderate, critical }

/// Chip de severidad — LEVE / MODERADO / CRÍTICO
/// Reglas UI_RULES.md: pill (border-radius 100px), 11px bold + dot de 7px
class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required this.severity});

  final SeverityLevel severity;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: AppTextStyles.label.copyWith(color: config.textColor),
          ),
        ],
      ),
    );
  }

  _SeverityConfig _configFor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.low:
        return _SeverityConfig(
          label: 'LEVE',
          bg: AppColors.chipLowBg,
          textColor: AppColors.chipLowText,
          dotColor: AppColors.severityLow,
          borderColor: AppColors.severityLow.withValues(alpha: 0.27),
        );
      case SeverityLevel.moderate:
        return _SeverityConfig(
          label: 'MODERADO',
          bg: AppColors.chipModerateBg,
          textColor: AppColors.chipModerateText,
          dotColor: AppColors.severityModerate,
          borderColor: AppColors.severityModerate.withValues(alpha: 0.27),
        );
      case SeverityLevel.critical:
        return _SeverityConfig(
          label: 'CRÍTICO',
          bg: AppColors.chipCriticalBg,
          textColor: AppColors.chipCriticalText,
          dotColor: AppColors.severityCritical,
          borderColor: AppColors.severityCritical.withValues(alpha: 0.27),
        );
    }
  }
}

class _SeverityConfig {
  const _SeverityConfig({
    required this.label,
    required this.bg,
    required this.textColor,
    required this.dotColor,
    required this.borderColor,
  });
  final String label;
  final Color bg;
  final Color textColor;
  final Color dotColor;
  final Color borderColor;
}
