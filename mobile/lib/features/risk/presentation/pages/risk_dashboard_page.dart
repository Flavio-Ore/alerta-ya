import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/presentation/bloc/risk_bloc.dart';

class RiskDashboardPage extends StatefulWidget {
  const RiskDashboardPage({super.key});

  @override
  State<RiskDashboardPage> createState() => _RiskDashboardPageState();
}

class _RiskDashboardPageState extends State<RiskDashboardPage> {
  static const double _defaultLat = -12.0464;
  static const double _defaultLng = -77.0428;

  late final RiskBloc _riskBloc;

  @override
  void initState() {
    super.initState();
    _riskBloc = getIt<RiskBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRisk());
  }

  Future<void> _loadRisk() async {
    final position = await _resolvePosition();
    if (!mounted) return;
    _riskBloc.add(RiskRequested(lat: position.lat, lng: position.lng));
  }

  Future<({double lat, double lng})> _resolvePosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (lat: _defaultLat, lng: _defaultLng);
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return (lat: _defaultLat, lng: _defaultLng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _riskBloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: BlocBuilder<RiskBloc, RiskState>(
            builder: (context, state) {
              if (state is RiskFailure) {
                return _ErrorState(message: state.message);
              }
              if (state is RiskLoaded) {
                return _RiskLoadedView(info: state.info);
              }
              // RiskInitial y RiskLoading comparten el mismo skeleton —
              // nunca dejamos la pantalla en blanco.
              return const _LoadingState();
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            'Calculando riesgo de la zona…',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.onSurfaceVariant,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar el mapa de riesgo',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revisá tu conexión e intentá de nuevo en unos minutos.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskLoadedView extends StatelessWidget {
  const _RiskLoadedView({required this.info});
  final RiskInfo info;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _Headline(info: info),
        if (!info.hasData) ...[
          const SizedBox(height: 12),
          const _LowConfidenceBanner(),
        ],
        const SizedBox(height: 20),
        _HeatmapCard(info: info),
        const SizedBox(height: 20),
        _BadHoursChart(info: info),
        const SizedBox(height: 20),
        _TopTypeCard(info: info),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.info});
  final RiskInfo info;

  Color get _levelColor => switch (info.level) {
        'high' => AppColors.severityCritical,
        'moderate' => AppColors.severityModerate,
        'low' => AppColors.severityLow,
        _ => AppColors.onSurfaceVariant,
      };

  String get _levelLabel => switch (info.level) {
        'high' => 'Riesgo alto',
        'moderate' => 'Riesgo moderado',
        'low' => 'Riesgo bajo',
        _ => 'Sin datos suficientes',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.district,
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _levelColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _levelLabel,
              style: AppTextStyles.titleMd.copyWith(color: _levelColor),
            ),
            if (info.riskScore != null) ...[
              const SizedBox(width: 8),
              Text(
                '· ${info.riskScore}/100',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _LowConfidenceBanner extends StatelessWidget {
  const _LowConfidenceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin datos suficientes para esta zona todavía.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.info});
  final RiskInfo info;

  Color _tileColor(double risk) {
    if (risk >= 67) return AppColors.severityCritical;
    if (risk >= 34) return AppColors.severityModerate;
    return AppColors.severityLow;
  }

  @override
  Widget build(BuildContext context) {
    final tiles = info.nearbyTiles;
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    final center = LatLng(tiles.first.lat, tiles.first.lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'pe.alertaya.app',
            ),
            CircleLayer(
              circles: tiles
                  .map(
                    (t) => CircleMarker(
                      point: LatLng(t.lat, t.lng),
                      radius: 18,
                      useRadiusInMeter: false,
                      color: _tileColor(t.risk).withValues(alpha: 0.35),
                      borderColor: _tileColor(t.risk),
                      borderStrokeWidth: 1.5,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadHoursChart extends StatelessWidget {
  const _BadHoursChart({required this.info});
  final RiskInfo info;

  static const double _maxBarHeight = 64;

  @override
  Widget build(BuildContext context) {
    final badHours = info.badHours.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horas más riesgosas',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _maxBarHeight + 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (hour) {
              final isBad = badHours.contains(hour);
              final heightFactor = isBad ? 1.0 : 0.35;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: _maxBarHeight * heightFactor,
                    decoration: BoxDecoration(
                      color: isBad
                          ? AppColors.severityCritical
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0h',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant)),
            Text('23h',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _TopTypeCard extends StatelessWidget {
  const _TopTypeCard({required this.info});
  final RiskInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.report_outlined, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo más frecuente',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  info.topType ?? 'Sin datos suficientes',
                  style: AppTextStyles.titleSm
                      .copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
