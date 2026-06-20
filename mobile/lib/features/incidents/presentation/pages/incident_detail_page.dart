import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/core/widgets/severity_chip.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/presentation/bloc/incidents_bloc.dart';

/// Ruta dedicada — usada para deep links (notificaciones push, share URL).
/// Para tap-en-pin desde el mapa usar [showIncidentDetailSheet] (bottom sheet modal).
class IncidentDetailPage extends StatelessWidget {
  const IncidentDetailPage({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<IncidentsBloc>()..add(IncidentDetailRequested(incidentId)),
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollController) => _SheetContainer(
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

/// Abre el detalle de un incidente como bottom sheet modal sobre el mapa.
/// Mantiene el mapa visible debajo y permite cerrar con drag-down o tap fuera.
Future<void> showIncidentDetailSheet({
  required BuildContext context,
  required String incidentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    useSafeArea: true,
    builder: (sheetCtx) => BlocProvider.value(
      value: getIt<IncidentsBloc>()..add(IncidentDetailRequested(incidentId)),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollController) => _SheetContainer(
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

// ─── Shell del sheet ──────────────────────────────────────────────────────────

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.mapSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: IncidentDetailSheetBody(scrollController: scrollController),
    );
  }
}

// ─── Body público (reusable desde tests / otros widgets) ─────────────────────

class IncidentDetailSheetBody extends StatelessWidget {
  const IncidentDetailSheetBody({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsBloc, IncidentsState>(
      builder: (context, state) {
        if (state is IncidentsLoaded) {
          // Spinner mientras carga (clearDetail eliminó el viejo) — evita data stale.
          if (state.detailLoading || state.selectedDetail == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          return _DetailContent(
            detail: state.selectedDetail!,
            scrollController: scrollController,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.scrollController,
  });
  final IncidentDetailEntity detail;
  final ScrollController scrollController;

  SeverityLevel _toSeverityLevel(Severity s) => switch (s) {
        Severity.low => SeverityLevel.low,
        Severity.moderate => SeverityLevel.moderate,
        Severity.critical => SeverityLevel.critical,
      };

  Color _severityColor(Severity s) => switch (s) {
        Severity.low => AppColors.severityLow,
        Severity.moderate => AppColors.severityModerate,
        Severity.critical => AppColors.severityCritical,
      };

  IconData _typeIcon(IncidentType t) => switch (t) {
        IncidentType.robbery => Icons.dangerous_outlined,
        IncidentType.accident => Icons.car_crash_outlined,
        IncidentType.suspicious => Icons.visibility_outlined,
        IncidentType.harassment => Icons.person_off_outlined,
        IncidentType.extortion => Icons.money_off_outlined,
      };

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(detail.severity);
    final typeIcon = _typeIcon(detail.type);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // ── Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mapOutlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Header: icono de tipo + info + close
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono con fondo de severidad
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: severityColor.withValues(alpha: 0.40),
                ),
              ),
              child: Icon(typeIcon, color: severityColor, size: 26),
            ),
            const SizedBox(width: 14),
            // Títulos e info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.type.label,
                    style: AppTextStyles.headlineSm
                        .copyWith(color: AppColors.mapOnSurface),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SeverityChip(severity: _toSeverityLevel(detail.severity)),
                      const SizedBox(width: 8),
                      _StatusBadge(status: detail.status),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close,
                  color: AppColors.mapOnSurfaceVariant, size: 20),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Metadatos: ubicación + tiempo
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 13, color: AppColors.mapOnSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                detail.district,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.mapOnSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.schedule_outlined,
                size: 13, color: AppColors.mapOnSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              _timeAgo(detail.createdAt),
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.mapOnSurfaceVariant),
            ),
          ],
        ),

        // ── Unidad asignada (si existe)
        if (detail.unitAssigned != null && detail.unitAssigned!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_police_outlined,
                  size: 13, color: AppColors.secondaryContainer),
              const SizedBox(width: 4),
              Text('Unidad: ${detail.unitAssigned}',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.secondaryContainer)),
            ],
          ),
        ],

        const SizedBox(height: 20),
        const Divider(height: 1, color: AppColors.mapOutline),
        const SizedBox(height: 16),

        // ── Contadores
        Row(
          children: [
            _CounterTile(
              icon: Icons.check_circle_outline,
              color: AppColors.secondary,
              label: 'Confirmados',
              count: detail.confirmCount,
            ),
            const SizedBox(width: 8),
            _CounterTile(
              icon: Icons.cancel_outlined,
              color: AppColors.severityModerate,
              label: 'Desmentidos',
              count: detail.denyCount,
            ),
            // const SizedBox(width: 8),
            // _CounterTile(
            //   icon: Icons.person_outline,
            //   color: AppColors.mapOnSurfaceVariant,
            //   label: 'Reportes',
            //   count: detail.reportCount,
            // ),
          ],
        ),

        // ── Indicadores de alerta (pill badges)
        if (detail.weaponReports > 0 ||
            detail.injuredReports > 0 ||
            detail.stillHereReports > 0) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (detail.weaponReports > 0)
                _AlertBadge(
                  icon: Icons.warning_amber_outlined,
                  label: '${detail.weaponReports} con arma',
                  color: AppColors.severityCritical,
                ),
              if (detail.injuredReports > 0)
                _AlertBadge(
                  icon: Icons.personal_injury_outlined,
                  label: '${detail.injuredReports} herido(s)',
                  color: AppColors.severityCritical,
                ),
              if (detail.stillHereReports > 0)
                _AlertBadge(
                  icon: Icons.visibility_outlined,
                  label: '${detail.stillHereReports} en el lugar',
                  color: AppColors.severityModerate,
                ),
            ],
          ),
        ],

        // ── Mensaje de la autoridad
        if (detail.feedback != null && detail.feedback!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mapSurfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.secondaryContainer.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined,
                    size: 16, color: AppColors.secondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensaje oficial',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.secondaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail.feedback!,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.mapOnSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        const Divider(height: 1, color: AppColors.mapOutline),
        const SizedBox(height: 16),

        // ── CTA: confirmación ciudadana
        // Text(
        //   '¿Sigue ocurriendo?',
        //   style: AppTextStyles.titleLg.copyWith(color: AppColors.mapOnSurface),
        // ),
        // const SizedBox(height: 4),
        // Text(
        //   'Tu respuesta ayuda a la comunidad.',
        //   style: AppTextStyles.bodyMd
        //       .copyWith(color: AppColors.mapOnSurfaceVariant),
        // ),
        // const SizedBox(height: 14),
        // Row(
        //   children: [
        //     Expanded(
        //       child: OutlinedButton.icon(
        //         onPressed: () {
        //           context.read<IncidentsBloc>().add(IncidentConfirmSubmitted(
        //                 id: detail.id,
        //                 stillHere: false,
        //               ));
        //           context.pop();
        //         },
        //         icon: const Icon(Icons.check, size: 18),
        //         label: const Text('Ya fue'),
        //         style: OutlinedButton.styleFrom(
        //           foregroundColor: AppColors.mapOnSurface,
        //           side: const BorderSide(color: AppColors.mapOutlineVariant),
        //           minimumSize: const Size.fromHeight(48),
        //           shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(999)),
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: FilledButton.icon(
        //         onPressed: () {
        //           context.read<IncidentsBloc>().add(IncidentConfirmSubmitted(
        //                 id: detail.id,
        //                 stillHere: true,
        //               ));
        //           context.pop();
        //         },
        //         icon: const Icon(Icons.warning_amber, size: 18),
        //         label: const Text('Sigue ahí'),
        //         style: FilledButton.styleFrom(
        //           backgroundColor: AppColors.severityCritical,
        //           foregroundColor: Colors.white,
        //           minimumSize: const Size.fromHeight(48),
        //           shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(999)),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.mapSurfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: AppTextStyles.titleLg.copyWith(
                  fontSize: 22,
                  color: AppColors.mapOnSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.mapOnSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: color)),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      IncidentStatus.active => (AppColors.severityCritical, 'Activo'),
      IncidentStatus.inAttention => (AppColors.secondary, 'En atención'),
      IncidentStatus.closed => (AppColors.mapOnSurfaceVariant, 'Cerrado'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.labelSm.copyWith(color: color)),
    );
  }
}
