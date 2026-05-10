import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
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
  double _userLat = _defaultLat;
  double _userLng = _defaultLng;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _mapController.dispose();
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
    getIt<SocketClient>().connect(lat: lat, lng: lng);
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
                      // Marcador de posición del usuario
                      Marker(
                        point: LatLng(_userLat, _userLng),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.bgLight, width: 2),
                          ),
                        ),
                      ),
                      // Marcadores de incidentes
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

              // Banner de confirmación de zona (llega por WebSocket)
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

              // Indicador de carga inicial de incidentes
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
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/report/type'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.bgLight,
            elevation: 0,
            icon: const Icon(Icons.add_alert_outlined),
            label: Text(
              'Reportar',
              style: AppTextStyles.buttonLabel.copyWith(fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}

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
