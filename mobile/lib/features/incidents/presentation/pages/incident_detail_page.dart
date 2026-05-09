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

class IncidentDetailPage extends StatelessWidget {
  const IncidentDetailPage({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<IncidentsBloc>()..add(IncidentDetailRequested(incidentId)),
      child: _IncidentDetailSheet(incidentId: incidentId),
    );
  }
}

class _IncidentDetailSheet extends StatelessWidget {
  const _IncidentDetailSheet({required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: BlocBuilder<IncidentsBloc, IncidentsState>(
            builder: (context, state) {
              if (state is IncidentsLoaded && state.detailLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is IncidentsLoaded && state.selectedDetail != null) {
                return _DetailContent(
                  detail: state.selectedDetail!,
                  scrollController: scrollController,
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent(
      {required this.detail, required this.scrollController});
  final IncidentDetailEntity detail;
  final ScrollController scrollController;

  SeverityLevel _toSeverityLevel(Severity s) => switch (s) {
        Severity.low => SeverityLevel.low,
        Severity.medium => SeverityLevel.moderate,
        Severity.high => SeverityLevel.critical,
      };

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text(detail.type.label, style: AppTextStyles.h2)),
            SeverityChip(severity: _toSeverityLevel(detail.severity)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => context.pop(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(detail.district, style: AppTextStyles.bodySecondary),
            const SizedBox(width: 12),
            _StatusBadge(status: detail.status),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _CounterTile(
              icon: Icons.check_circle_outline,
              color: AppColors.severityLow,
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
            const SizedBox(width: 8),
            _CounterTile(
              icon: Icons.person_outline,
              color: AppColors.textSecondary,
              label: 'Reportes',
              count: detail.reportCount,
            ),
          ],
        ),
        if (detail.weaponReports > 0 ||
            detail.injuredReports > 0 ||
            detail.stillHereReports > 0) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          if (detail.weaponReports > 0)
            _InfoRow(
              icon: Icons.warning_amber_outlined,
              color: AppColors.severityCritical,
              label: '${detail.weaponReports} reporte(s) mencionan arma',
            ),
          if (detail.injuredReports > 0)
            _InfoRow(
              icon: Icons.personal_injury_outlined,
              color: AppColors.severityCritical,
              label: '${detail.injuredReports} reporte(s) mencionan heridos',
            ),
          if (detail.stillHereReports > 0)
            _InfoRow(
              icon: Icons.visibility_outlined,
              color: AppColors.severityModerate,
              label:
                  '${detail.stillHereReports} persona(s) siguen en el lugar',
            ),
        ],
        if (detail.feedback != null && detail.feedback!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mensaje de autoridad',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(detail.feedback!, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('¿Sigue ocurriendo?', style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text('Tu respuesta ayuda a otros ciudadanos.',
            style: AppTextStyles.bodySecondary),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<IncidentsBloc>().add(IncidentConfirmSubmitted(
                        id: detail.id,
                        stillHere: false,
                      ));
                  context.pop();
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Ya fue'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.severityLow,
                  side: const BorderSide(color: AppColors.severityLow),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  context.read<IncidentsBloc>().add(IncidentConfirmSubmitted(
                        id: detail.id,
                        stillHere: true,
                      ));
                  context.pop();
                },
                icon: const Icon(Icons.warning_amber, size: 18),
                label: const Text('Sigue ahí'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.severityCritical,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text('$count',
                  style: AppTextStyles.h2.copyWith(fontSize: 18)),
              Text(label,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: AppTextStyles.caption)),
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
      IncidentStatus.pending => (AppColors.severityModerate, 'Pendiente'),
      IncidentStatus.active => (AppColors.severityCritical, 'Activo'),
      IncidentStatus.attended => (AppColors.severityLow, 'Atendido'),
      IncidentStatus.dismissed => (AppColors.textMuted, 'Descartado'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}
