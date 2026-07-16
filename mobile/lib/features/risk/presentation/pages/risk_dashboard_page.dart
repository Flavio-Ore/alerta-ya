import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/core/services/photon_service.dart';
import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/entities/risk_prediction.dart';
import 'package:alertaya/features/risk/presentation/bloc/risk_bloc.dart';
import 'package:alertaya/features/risk/presentation/pages/risk_address_search.dart';

class RiskDashboardPage extends StatefulWidget {
  const RiskDashboardPage({super.key});

  @override
  State<RiskDashboardPage> createState() => _RiskDashboardPageState();
}

class _RiskDashboardPageState extends State<RiskDashboardPage> {
  static const double _defaultLat = -12.0464;
  static const double _defaultLng = -77.0428;

  late final RiskBloc _riskBloc;
  double _userLat = _defaultLat;
  double _userLng = _defaultLng;
  String? _activeAddress;

  @override
  void initState() {
    super.initState();
    _riskBloc = getIt<RiskBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRisk());
  }

  Future<void> _loadRisk() async {
    final position = await _resolvePosition();
    if (!mounted) return;
    setState(() {
      _userLat = position.lat;
      _userLng = position.lng;
    });
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

  void _onSuggestionSelected(PhotonSuggestion suggestion) {
    setState(() => _activeAddress = suggestion.displayName);
    _riskBloc.add(RiskRequested(lat: suggestion.lat, lng: suggestion.lng));
  }

  /// Descarta la dirección buscada y recalcula el riesgo de la ubicación actual.
  void _useCurrentLocation() {
    setState(() => _activeAddress = null);
    _loadRisk();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _riskBloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: RiskAddressSearch(
                  userLat: _userLat,
                  userLng: _userLng,
                  onAddressSelected: _onSuggestionSelected,
                  onUseCurrentLocation: _useCurrentLocation,
                ),
              ),
              Expanded(
                child: BlocBuilder<RiskBloc, RiskState>(
                  builder: (context, state) {
                    if (state is RiskFailure) {
                      return _ErrorState(message: state.message);
                    }
                    if (state is RiskLoaded) {
                      return _RiskLoadedView(
                        info: state.info,
                        todayPrediction: state.todayPrediction,
                        tomorrowPrediction: state.tomorrowPrediction,
                        activeAddress: _activeAddress,
                      );
                    }
                    // RiskInitial y RiskLoading comparten el mismo skeleton —
                    // nunca dejamos la pantalla en blanco.
                    return const _LoadingState();
                  },
                ),
              ),
            ],
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
              'Revisa tu conexión e intenta de nuevo en unos minutos.',
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
  const _RiskLoadedView({
    required this.info,
    this.todayPrediction,
    this.tomorrowPrediction,
    this.activeAddress,
  });
  final RiskInfo info;
  final RiskPrediction? todayPrediction;
  final RiskPrediction? tomorrowPrediction;
  final String? activeAddress;

  @override
  Widget build(BuildContext context) {
    final today = todayPrediction;
    final tomorrow = tomorrowPrediction;
    final showPrediction = (today?.available ?? false) || (tomorrow?.available ?? false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _Headline(info: info, activeAddress: activeAddress),
        const SizedBox(height: 12),
        _VerdictBanner(level: info.level),
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
        if (info.hasSafeHours) ...[
          const SizedBox(height: 12),
          _SafestHoursCard(info: info),
        ],
        if (showPrediction) ...[
          const SizedBox(height: 20),
          _MlPredictionCard(today: today, tomorrow: tomorrow),
        ],
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.info, this.activeAddress});
  final RiskInfo info;
  final String? activeAddress;

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
          activeAddress ?? info.district,
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

/// Veredicto textual derivado de [RiskInfo.level] — "¿debería ir?".
class RiskVerdict {
  const RiskVerdict({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;
}

/// Mapea el nivel de riesgo a un veredicto accionable en español.
/// Función pura — testeable sin widgets.
RiskVerdict riskVerdictFor(String level) {
  return switch (level) {
    'high' => const RiskVerdict(
        message:
            'Zona de riesgo ALTO a esta hora — evita o ve acompañado',
        color: AppColors.severityCritical,
        icon: Icons.dangerous_outlined,
      ),
    'moderate' => const RiskVerdict(
        message: 'Riesgo moderado — mantente alerta',
        color: AppColors.severityModerate,
        icon: Icons.warning_amber_outlined,
      ),
    'low' => const RiskVerdict(
        message: 'Riesgo bajo',
        color: AppColors.severityLow,
        icon: Icons.check_circle_outline,
      ),
    _ => const RiskVerdict(
        message: 'Sin datos suficientes para esta zona',
        color: AppColors.onSurfaceVariant,
        icon: Icons.help_outline,
      ),
  };
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    final verdict = riskVerdictFor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: verdict.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(verdict.icon, color: verdict.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              verdict.message,
              style: AppTextStyles.bodyMd.copyWith(color: verdict.color),
            ),
          ),
        ],
      ),
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

/// Traduce el valor crudo del API a etiqueta en español. Lookup tolerante: si el
/// backend agrega un tipo/severidad nuevo, muestra el valor crudo en vez de
/// lanzar (IncidentType.fromValue usa firstWhere, que revienta si no matchea).
String _typeLabel(String? value) {
  if (value == null) return 'Sin datos suficientes';
  final match = IncidentType.values.where((e) => e.value == value);
  return match.isEmpty ? value : match.first.label;
}

String _severityLabel(String? value) {
  if (value == null) return 'Sin datos suficientes';
  final match = Severity.values.where((e) => e.value == value);
  return match.isEmpty ? value : match.first.label;
}

/// Card genérica de métrica — mismo contenedor para todas las de esta pantalla.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.hint,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.titleSm
                      .copyWith(color: AppColors.onSurface),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTypeCard extends StatelessWidget {
  const _TopTypeCard({required this.info});
  final RiskInfo info;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      icon: Icons.report_outlined,
      iconColor: AppColors.secondary,
      label: 'Tipo más frecuente',
      value: _typeLabel(info.topType),
      hint: info.topSeverity != null
          ? 'Severidad predominante: ${_severityLabel(info.topSeverity)}'
          : null,
    );
  }
}

/// Predicción del modelo ML (XGBoost). A diferencia del resto de la pantalla
/// (motor determinístico), esta distingue el día de semana: muestra hoy y mañana.
class _MlPredictionCard extends StatelessWidget {
  const _MlPredictionCard({this.today, this.tomorrow});

  final RiskPrediction? today;
  final RiskPrediction? tomorrow;

  static const List<String> _dayNames = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  Color _colorFor(int score) {
    if (score >= 67) return AppColors.severityCritical;
    if (score >= 34) return AppColors.severityModerate;
    return AppColors.severityLow;
  }

  Widget _row(String label, RiskPrediction? p) {
    final available = p?.available ?? false;
    final score = p?.riskScore;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
            ),
          ),
          if (available && score != null) ...[
            Text(
              '$score/100',
              style: AppTextStyles.titleSm.copyWith(color: _colorFor(score)),
            ),
          ] else
            Text(
              'No disponible',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_outlined, color: AppColors.secondary),
              const SizedBox(width: 12),
              Text(
                'Predicción del modelo (IA)',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Estimación por día de semana a esta hora.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (today != null) _row('Hoy · ${_dayNames[today!.dayOfWeek]}', today),
          if (tomorrow != null)
            _row('Mañana · ${_dayNames[tomorrow!.dayOfWeek]}', tomorrow),
        ],
      ),
    );
  }
}

/// Recomendación de horario. Solo se construye si el motor emitió horas seguras
/// — ver RiskInfo.hasSafeHours. Sin señal horaria no se recomienda nada.
class _SafestHoursCard extends StatelessWidget {
  const _SafestHoursCard({required this.info});
  final RiskInfo info;

  @override
  Widget build(BuildContext context) {
    final hours = [...info.safestHours]..sort();
    final label = hours.map((h) => '${h}h').join(' · ');
    return _MetricCard(
      icon: Icons.schedule_outlined,
      iconColor: AppColors.severityLow,
      label: 'Horas más seguras',
      value: label,
      hint: 'Menos incidentes registrados en esta zona.',
    );
  }
}
