import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/domain/ai_verdict.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';
import 'package:alertaya/features/my_reports/presentation/bloc/my_reports_bloc.dart';

class MyReportsTab extends StatelessWidget {
  const MyReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyReportsBloc, MyReportsState>(
      listenWhen: (_, s) => s is MyReportsCancelError,
      listener: (context, state) {
        if (state is MyReportsCancelError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.severityCritical,
            ),
          );
        }
      },
      buildWhen: (_, s) => s is! MyReportsCancelError,
      builder: (context, state) {
        if (state is MyReportsLoading || state is MyReportsInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MyReportsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<MyReportsBloc>().add(const MyReportsLoaded()),
          );
        }
        if (state is MyReportsData) {
          if (state.items.isEmpty) return const _EmptyView();
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<MyReportsBloc>().add(const MyReportsRefreshed()),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.outlineVariant,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (_, index) => _MyReportTile(
                report: state.items[index],
                onTap: () => _showDetailSheet(context, state.items[index]),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showDetailSheet(BuildContext context, MyReportEntity report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<MyReportsBloc>(),
        child: _ReportDetailSheet(report: report),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile en lista
// ─────────────────────────────────────────────────────────────────────────────

class _MyReportTile extends StatelessWidget {
  const _MyReportTile({required this.report, required this.onTap});
  final MyReportEntity report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final incident = report.incident;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(report.type), size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.type.label,
                    style:
                        AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(_timeAgo(report.createdAt), style: AppTextStyles.labelMd),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.outline),
              ],
            ),
            const SizedBox(height: 6),
            if (incident == null)
              const _PendingBadge()
            else ...[
              Row(
                children: [
                  _StatusBadge(status: incident.status),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(incident.district,
                        style: AppTextStyles.labelMd,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // "Por qué" en lenguaje humano — nunca un score crudo.
              // Never-blank: aiVerdictText() siempre devuelve un texto,
              // incluso cuando aiScore/aiVerified aún no llegan (PR1c).
              Text(
                aiVerdictText(incident.aiScore, incident.aiVerified),
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              if (incident.feedback != null &&
                  incident.feedback!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    incident.feedback!,
                    style: AppTextStyles.bodyMd,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(IncidentType type) => switch (type) {
        IncidentType.robbery => Icons.warning_amber_outlined,
        IncidentType.accident => Icons.car_crash_outlined,
        IncidentType.harassment => Icons.report_outlined,
        IncidentType.extortion => Icons.phone_disabled_outlined,
        IncidentType.suspicious => Icons.visibility_outlined,
      };

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet de detalle
// ─────────────────────────────────────────────────────────────────────────────

// ─── Mapas de traducción (basados en ReportFormSchemas) ──────────────────────

const _kQuestionLabels = <String, String>{
  // Robo/Asalto
  'personsInvolved': 'Personas involucradas',
  'weapon': 'Arma',
  'stillInArea': '¿Sigue en la zona?',
  // Accidente
  'injured': 'Heridos visibles',
  'vehicleCount': 'Vehículos involucrados',
  'blocksTraffic': '¿Bloquea el tráfico?',
  'medicalPresent': 'Presencia médica',
  // Notas / comunes
  'notes': 'Notas',
  'description': 'Descripción',
};

const _kOptionLabels = <String, String>{
  // personsInvolved
  'one': '1 persona',
  'two_three': '2–3 personas',
  'group': 'Grupo grande',
  // weapon
  'firearm': 'Arma de fuego',
  'blade': 'Arma blanca',
  'none': 'No',
  // stillInArea
  'yes': 'Sí',
  'fled_foot': 'Huyó a pie',
  'fled_vehicle': 'Huyó en vehículo',
  // injured
  'no': 'No',
  // vehicleCount
  'two': '2 vehículos',
  'more': 'Más de 2',
  // blocksTraffic
  'fully': 'Completamente',
  'partially': 'Parcialmente',
  // medicalPresent
  'incoming': 'En camino',
  // genérico
  'unknown': 'No sé / No vi',
};

// ─────────────────────────────────────────────────────────────────────────────

class _ReportDetailSheet extends StatefulWidget {
  const _ReportDetailSheet({required this.report});
  final MyReportEntity report;

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final incident = report.incident;
    final isPending = incident == null;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // ── Encabezado ───────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ícono del tipo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconFor(report.type),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Título + fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.type.label, style: AppTextStyles.headlineMd),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(report.createdAt),
                            style: AppTextStyles.labelMd,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Badge de estado (línea propia — sin competir con el título) ──
                if (isPending)
                  const _InfoBanner(
                    icon: Icons.hourglass_empty_rounded,
                    color: AppColors.secondary,
                    message: 'Pendiente: esperando confirmación de otros ciudadanos',
                  )
                else
                  Row(
                    children: [
                      _StatusBadge(status: incident.status),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          incident.district,
                          style: AppTextStyles.labelMd,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // ── Imágenes de evidencia ────────────────────────────────────
                if (report.mediaUrls.isNotEmpty) ...[
                  const _SectionLabel('Evidencia'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.mediaUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) =>
                          _EvidenceImage(url: report.mediaUrls[i]),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Datos del formulario ────────────────────────────────────
                if (_visibleFormData(report.formData).isNotEmpty) ...[
                  const _SectionLabel('Detalles del reporte'),
                  const SizedBox(height: 10),
                  _DataCard(
                    rows: _visibleFormData(report.formData)
                        .entries
                        .map((e) => _DataRow(
                              label: _kQuestionLabels[e.key] ?? e.key,
                              value: _kOptionLabels[e.value.toString()] ??
                                  e.value.toString(),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Feedback de autoridad (si existe) ───────────────────────
                if (incident != null &&
                    incident.feedback != null &&
                    incident.feedback!.isNotEmpty) ...[
                  const _SectionLabel('Mensaje de la autoridad'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            incident.feedback!,
                            style: AppTextStyles.bodyLg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Botón cancelar (solo reportes pendientes) ───────────────
                if (isPending) ...[
                  const Divider(color: AppColors.outlineVariant),
                  const SizedBox(height: 16),
                  _CancelButton(
                    cancelling: _cancelling,
                    onCancel: () => _confirmCancel(report.reportId),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _visibleFormData(Map<String, dynamic> data) =>
      Map.fromEntries(
        data.entries.where((e) => !e.key.startsWith('_') && e.value != null),
      );

  IconData _iconFor(IncidentType type) => switch (type) {
        IncidentType.robbery => Icons.warning_amber_outlined,
        IncidentType.accident => Icons.car_crash_outlined,
        IncidentType.harassment => Icons.report_outlined,
        IncidentType.extortion => Icons.phone_disabled_outlined,
        IncidentType.suspicious => Icons.visibility_outlined,
      };

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmCancel(String reportId) async {
    // Usar el context del State (no pasarlo como param) y darle al dialog
    // su propio context para popearse — nunca usar el context externo dentro del dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Cancelar reporte'),
        content: const Text(
          '¿Querés cancelar este reporte? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('No, dejarlo'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.severityCritical,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _cancelling = true);
    context.read<MyReportsBloc>().add(MyReportCancelRequested(reportId));
    if (mounted) Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de soporte del sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelMd.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });
  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelMd.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.rows});
  final List<_DataRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 3),
                    Text(row.value, style: AppTextStyles.bodyLg),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  color: AppColors.outlineVariant,
                  indent: 14,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EvidenceImage extends StatelessWidget {
  const _EvidenceImage({required this.url});
  final String url;

  static const _size = 160.0;

  static final _placeholder = Container(
    width: _size,
    height: _size,
    color: AppColors.surfaceContainerHigh,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );

  static final _errorWidget = Container(
    width: _size,
    height: _size,
    color: AppColors.surfaceContainerHigh,
    child: const Icon(
      Icons.broken_image_outlined,
      color: AppColors.outline,
      size: 36,
    ),
  );

  Future<String> _resolveUrl() async {
    if (!url.startsWith('gs://')) return url;
    return FirebaseStorage.instance.refFromURL(url).getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder<String>(
        future: _resolveUrl(),
        builder: (_, snapshot) {
          if (snapshot.hasError) return _errorWidget;
          if (!snapshot.hasData) return _placeholder;
          return CachedNetworkImage(
            imageUrl: snapshot.data!,
            width: _size,
            height: _size,
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholder,
            errorWidget: (_, __, ___) => _errorWidget,
          );
        },
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({
    required this.cancelling,
    required this.onCancel,
  });
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: cancelling ? null : onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.severityCritical,
          side: const BorderSide(color: AppColors.severityCritical),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: cancelling
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.severityCritical,
                ),
              )
            : const Icon(Icons.delete_outline, size: 18),
        label: Text(
          cancelling ? 'Cancelando...' : 'Cancelar reporte',
          style: AppTextStyles.bodyLg.copyWith(
            color: AppColors.severityCritical,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      IncidentStatus.active => (
          AppColors.severityCritical.withValues(alpha: 0.20),
          AppColors.severityCritical,
          'Activo',
        ),
      IncidentStatus.inAttention => (
          AppColors.severityModerate.withValues(alpha: 0.20),
          AppColors.severityModerate,
          'En atención',
        ),
      IncidentStatus.closed => (
          AppColors.severityLow.withValues(alpha: 0.20),
          AppColors.severityLow,
          'Cerrado',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty,
              size: 14, color: AppColors.onSurfaceVariant),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Pendiente: esperando confirmación de otros ciudadanos',
              style: AppTextStyles.labelMd,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: AppColors.outline),
            SizedBox(height: 16),
            Text('Sin reportes', style: AppTextStyles.headlineMd),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Cuando reportes un incidente lo vas a ver acá con el estado de la autoridad.',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.outline),
              const SizedBox(height: 16),
              const Text('No se pudo cargar', style: AppTextStyles.headlineMd),
              const SizedBox(height: 8),
              Text(message,
                  style: AppTextStyles.bodyMd,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}
