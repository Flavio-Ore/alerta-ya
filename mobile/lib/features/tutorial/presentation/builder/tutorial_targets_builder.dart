import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/tutorial/presentation/keys/tutorial_keys.dart';

/// Construye la lista de [TargetFocus] para el tutorial guiado de AlertaYa.
///
/// Orden:
///   1. Búsqueda en el mapa
///   2. Botón de reportar incidencias
///   3. Alertas (bottom nav)
///   4. Mapa de riesgo (bottom nav)
///   5. Botón de pánico (bottom nav)
List<TargetFocus> buildTutorialTargets(TutorialKeys keys) {
  const total = 5;

  return [
    _target(
      id: 'tutorial_search',
      key: keys.search,
      shape: ShapeLightFocus.RRect,
      radius: 14,
      step: 1,
      total: total,
      align: ContentAlign.bottom,
      title: 'Busca cualquier dirección',
      description:
          'Escribe una dirección o zona de Lima y el mapa te lleva ahí al instante.',
    ),
    _target(
      id: 'tutorial_report_fab',
      key: keys.reportFab,
      shape: ShapeLightFocus.RRect,
      radius: 14,
      step: 2,
      total: total,
      align: ContentAlign.top,
      title: 'Reporta un incidente',
      description:
          'Toca este botón para avisar lo que está pasando en tu zona en tiempo real.',
    ),
    _target(
      id: 'tutorial_alerts',
      key: keys.alerts,
      shape: ShapeLightFocus.Circle,
      step: 3,
      total: total,
      align: ContentAlign.top,
      title: 'Tus alertas',
      description:
          'Acá recibes notificaciones de incidentes cercanos a ti.',
    ),
    _target(
      id: 'tutorial_risk',
      key: keys.risk,
      shape: ShapeLightFocus.Circle,
      step: 4,
      total: total,
      align: ContentAlign.top,
      title: 'Mapa de riesgo',
      description:
          'Visualiza las zonas de mayor riesgo en Lima y planifica tus rutas con seguridad.',
    ),
    _target(
      id: 'tutorial_panic',
      key: keys.panic,
      shape: ShapeLightFocus.Circle,
      step: 5,
      total: total,
      align: ContentAlign.top,
      title: 'Botón de pánico',
      description:
          'Ante una emergencia, presiona acá: alertas a tus contactos de confianza al instante.',
      isLast: true,
    ),
  ];
}

TargetFocus _target({
  required String id,
  required GlobalKey key,
  required ShapeLightFocus shape,
  required int step,
  required int total,
  required ContentAlign align,
  required String title,
  required String description,
  double radius = 0,
  bool isLast = false,
}) {
  return TargetFocus(
    identify: id,
    keyTarget: key,
    shape: shape,
    radius: radius,
    paddingFocus: 10,
    contents: [
      TargetContent(
        align: align,
        builder: (context, controller) => _StepCard(
          step: step,
          total: total,
          title: title,
          description: description,
          isLast: isLast,
          onNext: () => controller.next(),
        ),
      ),
    ],
  );
}

// ─── Tarjeta de contenido por paso ────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.total,
    required this.title,
    required this.description,
    required this.isLast,
    required this.onNext,
  });

  final int step;
  final int total;
  final String title;
  final String description;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Indicador de progreso ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$step de $total',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 0.3,
                ),
              ),
              Row(
                children: List.generate(total, (i) {
                  final isActive = i == step - 1;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isActive ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.secondary
                          : AppColors.outline.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Título ────────────────────────────────────────────
          Text(title, style: AppTextStyles.titleMd),

          const SizedBox(height: 6),

          // ── Descripción ───────────────────────────────────────
          Text(description, style: AppTextStyles.bodyMd),

          const SizedBox(height: 16),

          // ── Botón de avance ───────────────────────────────────
          GestureDetector(
            onTap: onNext,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isLast ? '¡Entendido!' : 'Siguiente',
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.onSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
