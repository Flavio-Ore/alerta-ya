import 'package:flutter/material.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/map/domain/entities/incident_entity.dart';

class IncidentDetailSheet extends StatelessWidget {
  const IncidentDetailSheet({
    super.key,
    required this.incident,
    required this.onConfirm,
  });

  final IncidentEntity incident;
  final void Function(bool stillHere) onConfirm;

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (incident.severity) {
      Severity.low => AppColors.severityLow,
      Severity.moderate => AppColors.severityModerate,
      Severity.critical => AppColors.severityCritical,
    };

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Título con severidad
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: severityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${incident.severityLabel} · AV. LARCO, ${incident.district.toUpperCase()}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${incident.type.label} · Reportado ${incident.timeAgo} · ${incident.confirmCount} confirmaciones',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // Botones Waze — UI_RULES.md: side by side, 52px, radius 12
          Row(
            children: [
              Expanded(
                child: _WazeButton(
                  label: 'Sigue ahí',
                  icon: Icons.check_circle_outline,
                  color: AppColors.severityLow,
                  onTap: () => onConfirm(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WazeButton(
                  label: 'Ya no está',
                  icon: Icons.cancel_outlined,
                  color: AppColors.bgGray,
                  textColor: AppColors.textSecondary,
                  onTap: () => onConfirm(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WazeButton extends StatelessWidget {
  const _WazeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
