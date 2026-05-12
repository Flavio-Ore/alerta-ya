import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/core/realtime/socket_client.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:alertaya/features/map/presentation/widgets/incident_marker.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const double _defaultLat = -12.0464;
  static const double _defaultLng = -77.0428;
  static const double _defaultZoom = 14.0;

  late final MapController _mapController;
  final _searchController = TextEditingController();

  double _userLat = _defaultLat;
  double _userLng = _defaultLng;
  String? _selectedId;
  bool _searchLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final (:lat, :lng) = await _resolvePosition();
    if (!mounted) return;
    setState(() {
      _userLat = lat;
      _userLng = lng;
    });
    _mapController.move(LatLng(lat, lng), _defaultZoom);
    await getIt<SocketClient>().connect(lat: lat, lng: lng);
    if (!mounted) return;
    context.read<IncidentsBloc>().add(const IncidentsStarted());
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

  void _onMarkerTap(IncidentEntity incident) {
    setState(() => _selectedId = incident.id);
    context.push('/map/incident/${incident.id}').then((_) {
      if (mounted) setState(() => _selectedId = null);
    });
  }

  Future<void> _onSearchSubmit(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _searchLoading = true);
    try {
      final locations = await locationFromAddress('$q, Lima, Perú');
      if (locations.isNotEmpty && mounted) {
        _mapController.move(
          LatLng(locations.first.latitude, locations.first.longitude),
          _defaultZoom,
        );
      }
    } catch (_) {
      // Dirección no encontrada — no interrumpir al usuario
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  double _markerSize(Severity s) => switch (s) {
        Severity.high => 56.0,
        Severity.medium => 28.0,
        Severity.low => 24.0,
      };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsBloc, IncidentsState>(
      builder: (context, state) {
        final incidents =
            state is IncidentsLoaded ? state.incidents : <IncidentEntity>[];

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_userLat, _userLng),
                  initialZoom: _defaultZoom,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                  cameraConstraint: CameraConstraint.containCenter(
                    bounds: LatLngBounds(
                      const LatLng(-12.28, -77.17),
                      const LatLng(-11.77, -76.78),
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.alertaya.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_userLat, _userLng),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.bgLight, width: 2),
                          ),
                        ),
                      ),
                      ...incidents.map((incident) {
                        final size = _markerSize(incident.severity);
                        return Marker(
                          point: LatLng(incident.lat, incident.lng),
                          width: size,
                          height: size,
                          child: IncidentMarker(
                            key: ValueKey(incident.id),
                            severity: incident.severity,
                            isSelected: _selectedId == incident.id,
                            onTap: () => _onMarkerTap(incident),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),

              // Indicador de carga inicial
              if (state is IncidentsLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    color: AppColors.accent,
                    backgroundColor: Colors.transparent,
                  ),
                ),

              // Overlay: búsqueda + riesgo de zona
              _SearchOverlay(
                controller: _searchController,
                isLoading: _searchLoading,
                onSubmit: _onSearchSubmit,
                incidents: incidents,
                userLat: _userLat,
                userLng: _userLng,
                onRouteTap: () => context.push(
                  '/map/routes',
                  extra: LatLng(_userLat, _userLng),
                ),
              ),

              // Banner de confirmación de zona (WebSocket) — siempre encima del overlay
              if (state is IncidentsLoaded &&
                  state.pendingConfirmRequest != null)
                _ConfirmRequestBanner(
                  event: state.pendingConfirmRequest!,
                  onYes: () => context.read<IncidentsBloc>().add(
                        ZoneConfirmSubmitted(
                          zoneKey: state.pendingConfirmRequest!.zoneLabel,
                          response: 'yes',
                        ),
                      ),
                  onNo: () => context.read<IncidentsBloc>().add(
                        ZoneConfirmSubmitted(
                          zoneKey: state.pendingConfirmRequest!.zoneLabel,
                          response: 'no',
                        ),
                      ),
                  onDismiss: () => context
                      .read<IncidentsBloc>()
                      .add(const ConfirmRequestDismissed()),
                ),
            ],
          ),
          floatingActionButton: _AnimatedReportFab(
            onPressed: () => context.push('/report/type'),
          ),
        );
      },
    );
  }
}

// ─── Search + Risk overlay ─────────────────────────────────────────────────────

class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    required this.incidents,
    required this.userLat,
    required this.userLng,
    required this.onRouteTap,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onSubmit;
  final List<IncidentEntity> incidents;
  final double userLat;
  final double userLng;
  final VoidCallback onRouteTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final zoneRisk = _computeZoneRisk(incidents, userLat, userLng);

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            color: AppColors.bgLight,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/logo/alertaya_logo_horizontal.svg',
                        height: 28,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.route_outlined,
                            color: AppColors.primary),
                        tooltip: 'Comparar rutas',
                        onPressed: onRouteTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: AppColors.textSecondary),
                        tooltip: 'Alertas',
                        onPressed: () => context.go('/alerts'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bgGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(Icons.search,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Buscar dirección o zona...',
                              hintStyle: AppTextStyles.bodySecondary
                                  .copyWith(fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              suffixIcon: isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                            style:
                                AppTextStyles.body.copyWith(fontSize: 13),
                            onSubmitted: onSubmit,
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ZoneRiskChip(risk: zoneRisk),
        ],
      ),
    );
  }

  _ZoneRisk _computeZoneRisk(
      List<IncidentEntity> incidents, double lat, double lng) {
    const distance = Distance();
    const radiusMeters = 600.0;
    final nearby = incidents.where((i) {
      return distance(LatLng(lat, lng), LatLng(i.lat, i.lng)) <=
          radiusMeters;
    }).toList();

    if (nearby.isEmpty) return _ZoneRisk.clear;
    if (nearby.any((i) => i.severity == Severity.high)) {
      return _ZoneRisk.critical;
    }
    if (nearby.any((i) => i.severity == Severity.medium)) {
      return _ZoneRisk.moderate;
    }
    return _ZoneRisk.low;
  }
}

enum _ZoneRisk { clear, low, moderate, critical }

class _ZoneRiskChip extends StatelessWidget {
  const _ZoneRiskChip({required this.risk});

  final _ZoneRisk risk;

  @override
  Widget build(BuildContext context) {
    if (risk == _ZoneRisk.clear) return const SizedBox.shrink();

    final (color, label) = switch (risk) {
      _ZoneRisk.low => (AppColors.severityLow, 'Zona: LEVE'),
      _ZoneRisk.moderate => (AppColors.severityModerate, 'Zona: MODERADO'),
      _ZoneRisk.critical => (AppColors.severityCritical, 'Zona: CRÍTICO'),
      _ZoneRisk.clear => (AppColors.textMuted, ''),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zone confirm banner (WebSocket) ──────────────────────────────────────────

class _ConfirmRequestBanner extends StatelessWidget {
  const _ConfirmRequestBanner({
    required this.event,
    required this.onYes,
    required this.onNo,
    required this.onDismiss,
  });

  final ConfirmRequestEvent event;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        color: AppColors.dark,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Viste algo en ${event.zoneLabel}?',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textWhite),
                    ),
                    Text(
                      event.type.label,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onNo,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: onYes,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.dark,
                  minimumSize: const Size(60, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Sí'),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 16, color: AppColors.textMuted),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated report FAB ───────────────────────────────────────────────────────

class _AnimatedReportFab extends StatefulWidget {
  const _AnimatedReportFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AnimatedReportFab> createState() => _AnimatedReportFabState();
}

class _AnimatedReportFabState extends State<_AnimatedReportFab> {
  // Static: survives navigation, resets only on full app restart.
  static bool _hasAnimated = false;

  bool _extended = false;

  @override
  void initState() {
    super.initState();
    if (!_hasAnimated) {
      _hasAnimated = true;
      _extended = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _extended = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_alert_outlined, color: AppColors.bgLight),
                AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: _extended
                      ? Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              'Reportar incidencias',
                              style: AppTextStyles.buttonLabel
                                  .copyWith(fontSize: 14, color: AppColors.bgLight),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
