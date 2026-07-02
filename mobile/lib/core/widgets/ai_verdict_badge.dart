import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/domain/ai_verdict.dart';

/// Pill + icono de veredicto de IA — 3 estados, SIEMPRE visualmente
/// distinto del eje de severidad (ver AppColors.aiVerified/aiSuspicious/
/// aiNotEvaluated — nunca reusan severityModerate/severityCritical).
/// Never-blank: siempre renderiza uno de los 3 estados, nunca null/vacío.
class AiVerdictBadge extends StatelessWidget {
  const AiVerdictBadge({super.key, required this.score, required this.verified});

  final double? score;
  final bool? verified;

  @override
  Widget build(BuildContext context) {
    final state = aiVerdict(score, verified);
    final config = _configFor(state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: config.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 5),
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

  _AiVerdictConfig _configFor(AiVerdictState state) {
    switch (state) {
      case AiVerdictState.verified:
        return const _AiVerdictConfig(
          label: 'Confiable',
          icon: Icons.verified,
          color: AppColors.aiVerified,
        );
      case AiVerdictState.suspicious:
        return const _AiVerdictConfig(
          label: 'Por revisar',
          icon: Icons.gpp_maybe,
          color: AppColors.aiSuspicious,
        );
      case AiVerdictState.notEvaluated:
        return const _AiVerdictConfig(
          label: 'Sin evaluar',
          icon: Icons.help_outline,
          color: AppColors.aiNotEvaluated,
        );
    }
  }
}

class _AiVerdictConfig {
  const _AiVerdictConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;
}
