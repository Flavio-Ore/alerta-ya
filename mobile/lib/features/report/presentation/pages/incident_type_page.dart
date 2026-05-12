import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/presentation/bloc/report_bloc.dart';

class IncidentTypePage extends StatefulWidget {
  const IncidentTypePage({super.key});

  @override
  State<IncidentTypePage> createState() => _IncidentTypePageState();
}

class _IncidentTypePageState extends State<IncidentTypePage> {
  IncidentType? _selected;

  static const _enabledTypes = {IncidentType.robbery, IncidentType.accident};

  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(const ReportStarted());
  }

  void _continue() {
    if (_selected == null) return;
    context.push('/report/form/${_selected!.value}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Reportar Incidente', style: AppTextStyles.h2.copyWith(fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => context.go('/map'),
          ),
        ],
      ),
      body: Column(
        children: [
          const _ProgressBar(step: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paso 1 de 3 — ¿Qué está pasando?',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _GpsChip(),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: IncidentType.values.map((type) {
                      final isEnabled = _enabledTypes.contains(type);
                      return _TypeCard(
                        type: type,
                        isEnabled: isEnabled,
                        isSelected: _selected == type,
                        onTap: isEnabled
                            ? () => setState(() => _selected = type)
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _InfoCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: AlertaYaButton(
          label: 'Continuar',
          onPressed: _selected != null ? _continue : null,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: step / 3,
      backgroundColor: AppColors.bgGray,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 3,
    );
  }
}

class _GpsChip extends StatefulWidget {
  const _GpsChip();

  @override
  State<_GpsChip> createState() => _GpsChipState();
}

class _GpsChipState extends State<_GpsChip> {
  // null = cargando, '' = fallback, non-empty = ubicación real
  String? _location;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocation('');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isEmpty) {
        _setLocation('');
        return;
      }

      final p = placemarks.first;
      final label = _pickLabel(p);
      _setLocation(label);
    } catch (_) {
      _setLocation('');
    }
  }

  String _pickLabel(Placemark p) {
    final district =
        p.subLocality?.isNotEmpty == true ? p.subLocality! : null;
    final city = p.locality?.isNotEmpty == true ? p.locality! : null;
    return district ?? city ?? '';
  }

  void _setLocation(String value) {
    if (mounted) setState(() => _location = value);
  }

  @override
  Widget build(BuildContext context) {
    final loading = _location == null;
    final label = loading
        ? 'Obteniendo ubicación...'
        : _location!.isNotEmpty
            ? 'GPS activo · $_location'
            : 'GPS activo · Lima, Perú';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.severityLow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border:
            Border.all(color: AppColors.severityLow.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.severityLow,
              ),
            )
          else
            const Icon(Icons.location_on, color: AppColors.severityLow, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.severityLow,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
  });
  final IncidentType type;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final config = _cardConfig(type);
    final bgColor = isSelected
        ? AppColors.primary
        : isEnabled
            ? AppColors.bgLight
            : AppColors.bgGray;
    final borderColor = isSelected ? AppColors.primary : AppColors.textMuted;
    final iconColor = isSelected
        ? AppColors.bgLight
        : isEnabled
            ? config.color
            : AppColors.textMuted;
    final labelColor = isSelected ? AppColors.bgLight : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isSelected ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              type.label,
              style: AppTextStyles.body.copyWith(
                color: isEnabled ? labelColor : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (!isEnabled) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Próximamente',
                  style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _CardConfig _cardConfig(IncidentType type) => switch (type) {
        IncidentType.robbery =>
          const _CardConfig(icon: Icons.person_off_outlined, color: AppColors.severityCritical),
        IncidentType.accident =>
          const _CardConfig(icon: Icons.car_crash_outlined, color: AppColors.severityModerate),
        IncidentType.suspicious =>
          const _CardConfig(icon: Icons.visibility_outlined, color: AppColors.textSecondary),
        IncidentType.harassment =>
          const _CardConfig(icon: Icons.warning_amber_outlined, color: AppColors.severityModerate),
        IncidentType.extortion =>
          const _CardConfig(icon: Icons.phone_locked_outlined, color: AppColors.severityCritical),
      };
}

class _CardConfig {
  const _CardConfig({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seleccionar la categoría correcta ayuda a las unidades de respuesta a prepararse antes de llegar.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
