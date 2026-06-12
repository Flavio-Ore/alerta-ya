import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';

enum SeverityLevel { low, moderate, critical }

/// Chip de severidad — LEVE / MODERADO / CRÍTICO.
/// Urban Sentinel: pill, fondo color @20%, texto a 100%, sin border.
class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required this.severity});

  final SeverityLevel severity;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: AppTextStyles.labelMd.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _SeverityConfig _configFor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.low:
        return const _SeverityConfig(
          label: 'LEVE',
          color: AppColors.severityLow,
        );
      case SeverityLevel.moderate:
        return const _SeverityConfig(
          label: 'MODERADO',
          color: AppColors.severityModerate,
        );
      case SeverityLevel.critical:
        return const _SeverityConfig(
          label: 'CRÍTICO',
          color: AppColors.severityCritical,
        );
    }
  }
}

class _SeverityConfig {
  const _SeverityConfig({required this.label, required this.color});
  final String label;
  final Color color;
}
