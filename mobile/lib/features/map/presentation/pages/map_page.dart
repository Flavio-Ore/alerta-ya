import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/features/tutorial/presentation/keys/tutorial_keys.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/services/fcm_service.dart';
import 'package:alertaya/core/services/location_service.dart';
import 'package:alertaya/core/services/photon_service.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/core/realtime/socket_client.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:alertaya/features/incidents/presentation/pages/incident_detail_page.dart';
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
  static const double _filterRadiusMeters = 1000.0;
  // Radio para mostrar el sheet "¿Sigue ahí?" — incidentes cercanos al usuario.
  static const double _nearbyConfirmRadiusMeters = 500.0;

  late final MapController _mapController;
  StreamSubscription<({double lat, double lng})>? _positionSub;

  double _userLat = _defaultLat;
  double _userLng = _defaultLng;
  String? _selectedId;
  // IDs de incidentes ya prompteados al usuario en esta sesión (no re-preguntar).
  final Set<String> _shownNearbyConfirmIds = <String>{};

  // Filtro por dirección buscada — null = sin filtro.
  LatLng? _searchedLocation;
  String? _searchedLabel;

  // Botón "ir a mi ubicación" — visible cuando la cámara se alejó.
  bool _showRecenterButton = false;
  static const double _recenterThresholdMeters = 200.0;

  // Leyenda de colores de los puntos — colapsada por defecto.
  bool _showLegend = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
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
    await getIt<SocketClient>().connect(lat: lat, lng: lng);
    // Actualizar device_token con proxTile actual — habilita FCM tile-filtered.
    unawaited(getIt<FcmService>().updateLocation(lat: lat, lng: lng));
    if (!mounted) return;
    context.read<IncidentsBloc>().add(const IncidentsStarted());
    _startLocationUpdates();
  }

  /// Sigue la ubicación en vivo mientras el usuario se mueve — así el punto azul,
  /// el radio de zona y la detección de incidentes cercanos dejan de quedar
  /// congelados hasta reiniciar la app. No mueve la cámara (respeta el paneo
  /// manual); solo actualiza la posición de referencia.
  void _startLocationUpdates() {
    _positionSub?.cancel();
    _positionSub = getIt<LocationService>().positionStream().listen((pos) {
      if (!mounted) return;
      setState(() {
        _userLat = pos.lat;
        _userLng = pos.lng;
      });
    });
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
    showIncidentDetailSheet(
      context: context,
      incidentId: incident.id,
    ).then((_) {
      if (mounted) setState(() => _selectedId = null);
    });
  }

  void _onLocationSelected(LatLng point, String label) {
    setState(() {
      _searchedLocation = point;
      _searchedLabel = label;
      // La búsqueda mueve la cámara programáticamente (sin gesto), así que
      // _onMapPositionChanged no se dispara. Forzamos el botón de recentrar.
      _showRecenterButton = true;
    });
    _mapController.move(point, 15.5);
  }

  void _clearSearch() {
    setState(() {
      _searchedLocation = null;
      _searchedLabel = null;
    });
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    // Solo actualiza si el cambio vino de gesto del usuario (no programático).
    if (!hasGesture) return;
    final center = position.center;
    if (center == null) return;
    const distance = Distance();
    final meters = distance(center, LatLng(_userLat, _userLng));
    final shouldShow = meters > _recenterThresholdMeters;
    if (shouldShow != _showRecenterButton) {
      setState(() => _showRecenterButton = shouldShow);
    }
  }

  void _recenterOnUser() {
    _mapController.move(LatLng(_userLat, _userLng), _defaultZoom);
    setState(() => _showRecenterButton = false);
  }

  double _markerSize(Severity s) => switch (s) {
        Severity.critical => 56.0,
        Severity.moderate => 28.0,
        Severity.low => 24.0,
      };

  // Considera "cerca" todo lo que esté dentro del radio del feed local del usuario.
  // Si NO hay ningún incidente dentro de este radio, mostramos el empty state.
  static const double _nearbyZoneRadiusMeters = 2000.0;

  bool _noIncidentsNearby(List<IncidentEntity> incidents) {
    if (incidents.isEmpty) return true;
    const distance = Distance();
    final userPos = LatLng(_userLat, _userLng);
    for (final i in incidents) {
      final meters = distance.as(
        LengthUnit.Meter,
        userPos,
        LatLng(i.lat, i.lng),
      );
      if (meters <= _nearbyZoneRadiusMeters) return false;
    }
    return true;
  }

  // Track para no spamear el snack: solo mostrarlo una vez por carga.
  bool _emptyZoneSnackShown = false;
  // Track para no re-abrir el confirm-request sheet si ya está visible.
  bool _confirmRequestSheetShown = false;

  Future<void> _showConfirmRequestSheet(
    BuildContext context,
    ConfirmRequestEvent event,
  ) async {
    final bloc = context.read<IncidentsBloc>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _ConfirmRequestSheet(
        event: event,
        onSeen: () {
          bloc.add(ZoneConfirmSubmitted(
            zoneKey: event.zoneLabel,
            response: 'yes',
          ));
          Navigator.of(context).pop();
        },
        onNotSeen: () {
          bloc.add(ZoneConfirmSubmitted(
            zoneKey: event.zoneLabel,
            response: 'no',
          ));
          Navigator.of(context).pop();
        },
      ),
    );
    // Cuando se cierra (por cualquier vía), limpiar flag y dismiss en bloc.
    _confirmRequestSheetShown = false;
    if (mounted) {
      this.context.read<IncidentsBloc>().add(const ConfirmRequestDismissed());
    }
  }

  void _maybeShowEmptyZoneSnack(BuildContext context, List<IncidentEntity> incidents) {
    if (!_noIncidentsNearby(incidents)) {
      _emptyZoneSnackShown = false;
      return;
    }
    if (_emptyZoneSnackShown) return;
    _emptyZoneSnackShown = true;

    final msg = incidents.isEmpty
        ? 'Sin incidentes activos en Lima por ahora'
        : 'Por el momento no hay incidentes en tu zona';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success.withValues(alpha: 0.95),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          content: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Busca el incidente activo más cercano al usuario y, si está dentro del
  // radio y aún no fue prompteado, abre el sheet "¿Sigue ahí?".
  void _maybeShowNearbyConfirm(List<IncidentEntity> incidents) {
    if (incidents.isEmpty) return;
    const distance = Distance();
    final userPos = LatLng(_userLat, _userLng);

    IncidentEntity? closest;
    double closestMeters = double.infinity;
    for (final i in incidents) {
      if (_shownNearbyConfirmIds.contains(i.id)) continue;
      final meters = distance.as(
        LengthUnit.Meter,
        userPos,
        LatLng(i.lat, i.lng),
      );
      if (meters < closestMeters) {
        closestMeters = meters;
        closest = i;
      }
    }

    if (closest == null || closestMeters > _nearbyConfirmRadiusMeters) return;

    _shownNearbyConfirmIds.add(closest.id);
    final incident = closest;
    // Postergamos un frame para evitar abrir el sheet durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: false,
        builder: (_) => _NearbyConfirmSheet(
          incident: incident,
          onStillHere: () {
            context.read<IncidentsBloc>().add(
                  IncidentConfirmSubmitted(id: incident.id, stillHere: true),
                );
            Navigator.of(context).pop();
          },
          onGone: () {
            context.read<IncidentsBloc>().add(
                  IncidentConfirmSubmitted(id: incident.id, stillHere: false),
                );
            Navigator.of(context).pop();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IncidentsBloc, IncidentsState>(
      listenWhen: (prev, curr) {
        if (curr is! IncidentsLoaded) return false;
        if (prev is! IncidentsLoaded) return true;
        // Reaccionar a cambios de incidentes O a un nuevo confirm-request entrante.
        return prev.incidents.length != curr.incidents.length ||
            prev.pendingConfirmRequest != curr.pendingConfirmRequest;
      },
      listener: (context, state) {
        if (state is! IncidentsLoaded) return;
        _maybeShowNearbyConfirm(state.incidents);
        _maybeShowEmptyZoneSnack(context, state.incidents);
        // Confirm-request entrante → abrir bottom sheet (no más banner top).
        final req = state.pendingConfirmRequest;
        if (req != null && !_confirmRequestSheetShown) {
          _confirmRequestSheetShown = true;
          _showConfirmRequestSheet(context, req);
        }
      },
      builder: (context, state) {
        final allIncidents =
            state is IncidentsLoaded ? state.incidents : <IncidentEntity>[];

        // Filtrado por radio cuando hay una dirección buscada activa.
        final incidents = _searchedLocation == null
            ? allIncidents
            : allIncidents.where((i) {
                const distance = Distance();
                return distance(
                      _searchedLocation!,
                      LatLng(i.lat, i.lng),
                    ) <=
                    _filterRadiusMeters;
              }).toList();

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
                  onPositionChanged: _onMapPositionChanged,
                ),
                children: [
                  TileLayer(
                    // Voyager: light style con tints sutiles que dan más vida que light_all.
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: RetinaMode.isHighDensity(context),
                    userAgentPackageName: 'pe.alertaya.app',
                  ),
                  // Círculo del radio de filtro (solo visible si hay búsqueda activa)
                  if (_searchedLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _searchedLocation!,
                          radius: _filterRadiusMeters,
                          useRadiusInMeter: true,
                          color: AppColors.primaryContainer
                              .withValues(alpha: 0.08),
                          borderColor: AppColors.primaryContainer
                              .withValues(alpha: 0.5),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      // Pin de la dirección buscada
                      if (_searchedLocation != null)
                        Marker(
                          point: _searchedLocation!,
                          width: 44,
                          height: 52,
                          alignment: Alignment.bottomCenter,
                          child: const _SearchedLocationPin(),
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
                      // Ubicación del usuario — SIEMPRE al final = encima de todo,
                      // así ningún incidente en tu posición te tapa. Punto azul
                      // con halo pulsante (patrón "blue dot" de Google Maps).
                      Marker(
                        point: LatLng(_userLat, _userLng),
                        width: 44,
                        height: 44,
                        child: const _UserLocationMarker(),
                      ),
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
                    color: AppColors.secondary,
                    backgroundColor: Colors.transparent,
                  ),
                ),

              // Empty state — convertido a SnackBar 3s (ver _maybeShowEmptyZoneSnack).

              // Banner de error con retry — si la carga inicial falló
              if (state is IncidentsFailure)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: AppColors.severityCritical,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No se pudo cargar incidentes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context
                                .read<IncidentsBloc>()
                                .add(const IncidentsStarted()),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Leyenda de los puntos (esquina inferior izquierda)
              Positioned(
                left: 12,
                bottom: 100,
                child: _MapLegend(
                  expanded: _showLegend,
                  onToggle: () => setState(() => _showLegend = !_showLegend),
                ),
              ),

              // Overlay: búsqueda + riesgo de zona
              _SearchOverlay(
                key: getIt<TutorialKeys>().search,
                incidents: incidents,
                userLat: _userLat,
                userLng: _userLng,
                searchedLabel: _searchedLabel,
                radiusMeters: _filterRadiusMeters,
                onLocationSelected: _onLocationSelected,
                onClearSearch: _clearSearch,
              ),

              // Confirm-request UI: ahora se muestra como bottom sheet desde el
              // listener (_showConfirmRequestSheet). Antes era un banner top.
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _showRecenterButton
                    ? _RecenterFab(
                        key: const ValueKey('recenter'),
                        onPressed: _recenterOnUser,
                      )
                    : const SizedBox(key: ValueKey('empty'), height: 0),
              ),
              if (_showRecenterButton) const SizedBox(height: 12),
              _AnimatedReportFab(
                key: getIt<TutorialKeys>().reportFab,
                onPressed: () => context.push('/report/type'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Search + Risk overlay ─────────────────────────────────────────────────────

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay({
    super.key,
    required this.incidents,
    required this.userLat,
    required this.userLng,
    required this.searchedLabel,
    required this.radiusMeters,
    required this.onLocationSelected,
    required this.onClearSearch,
  });

  final List<IncidentEntity> incidents;
  final double userLat;
  final double userLng;
  final String? searchedLabel;
  final double radiusMeters;
  final void Function(LatLng point, String label) onLocationSelected;
  final VoidCallback onClearSearch;

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _controller = TextEditingController();
  final _photon = PhotonService();
  Timer? _debounce;
  List<PhotonSuggestion> _suggestions = [];
  bool _searching = false;
  bool _hasError = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      if (_suggestions.isNotEmpty || _hasError) {
        setState(() {
          _suggestions = [];
          _hasError = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() {
        _searching = true;
        _hasError = false;
      });
      final result = await _photon.suggest(
        value,
        lat: widget.userLat,
        lng: widget.userLng,
      );
      if (!mounted) return;
      setState(() {
        _searching = false;
        switch (result) {
          case PhotonSuccess(:final suggestions):
            _suggestions = suggestions;
            _hasError = false;
          case PhotonNetworkError():
            _suggestions = [];
            _hasError = true;
        }
      });
    });
  }

  void _onSuggestionTap(PhotonSuggestion s) {
    _controller.text = s.displayName;
    setState(() {
      _suggestions = [];
      _hasError = false;
    });
    FocusScope.of(context).unfocus();
    widget.onLocationSelected(LatLng(s.lat, s.lng), s.displayName);
  }

  void _clearInput() {
    _controller.clear();
    setState(() {
      _suggestions = [];
      _hasError = false;
    });
    widget.onClearSearch();
  }

  String _formatRadius(double meters) {
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final zoneRisk = _computeZoneRisk(widget.incidents, widget.userLat, widget.userLng);

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
            color: AppColors.mapSurface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/logo/alertaya_logo_horizontal.svg',
                        height: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.mapOnSurfaceVariant.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      cursorColor: AppColors.primaryContainer,
                      textAlignVertical: TextAlignVertical.center,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontSize: 14,
                        color: AppColors.mapOnSurface,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        if (_suggestions.isNotEmpty) {
                          _onSuggestionTap(_suggestions.first);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar dirección o zona...',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          fontSize: 14,
                          color: AppColors.mapOnSurfaceVariant,
                        ),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 12),
                        // Lupa dentro del input para que Material la alinee
                        // verticalmente con el placeholder.
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.mapOnSurfaceVariant, size: 20),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 40,
                        ),
                        // Espacio fijo para evitar layout shift entre estados.
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        suffixIcon: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: _searching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.primaryContainer,
                                    ),
                                  )
                                : (_controller.text.isNotEmpty ||
                                        widget.searchedLabel != null)
                                    ? InkResponse(
                                        onTap: _clearInput,
                                        radius: 18,
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: AppColors.mapOnSurfaceVariant,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Dropdown de sugerencias o feedback de error
          if (_hasError) ...[
            const SizedBox(height: 4),
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.mapSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 18, color: AppColors.severityCritical),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sin conexión. No se pudo buscar.',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.mapOnSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.mapSurface,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, indent: 16, color: AppColors.mapOutline),
                itemBuilder: (context, i) {
                  final s = _suggestions[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.mapOnSurfaceVariant),
                    title: Text(
                      s.displayName,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.mapOnSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _onSuggestionTap(s),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Si hay filtro activo, mostrar chip con label + clear. Si no, riesgo de zona.
          if (widget.searchedLabel != null)
            _ActiveFilterChip(
              label: widget.searchedLabel!,
              radiusLabel: _formatRadius(widget.radiusMeters),
              matchCount: widget.incidents.length,
              onClear: _clearInput,
            )
          else
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
      return distance(LatLng(lat, lng), LatLng(i.lat, i.lng)) <= radiusMeters;
    }).toList();

    if (nearby.isEmpty) return _ZoneRisk.clear;
    if (nearby.any((i) => i.severity == Severity.critical)) {
      return _ZoneRisk.critical;
    }
    if (nearby.any((i) => i.severity == Severity.moderate)) {
      return _ZoneRisk.moderate;
    }
    return _ZoneRisk.low;
  }
}

// ─── Chip de filtro activo por dirección buscada ──────────────────────────────

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.radiusLabel,
    required this.matchCount,
    required this.onClear,
  });

  final String label;
  final String radiusLabel;
  final int matchCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: AppColors.mapSurface,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded,
                size: 14, color: AppColors.primaryContainer),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.mapOnSurface,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· $radiusLabel · $matchCount',
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.mapOnSurfaceVariant),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onClear,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 14, color: AppColors.mapOnSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
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
      _ZoneRisk.clear => (AppColors.outline, ''),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
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

// ─── Sheet "¿Viste algo?" — confirm-request del primer reporte ──────────────

class _ConfirmRequestSheet extends StatefulWidget {
  const _ConfirmRequestSheet({
    required this.event,
    required this.onSeen,
    required this.onNotSeen,
  });

  final ConfirmRequestEvent event;
  final VoidCallback onSeen;
  final VoidCallback onNotSeen;

  @override
  State<_ConfirmRequestSheet> createState() => _ConfirmRequestSheetState();
}

class _ConfirmRequestSheetState extends State<_ConfirmRequestSheet> {
  String? _streetAddress;
  bool _loadingAddress = true;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    final lat = widget.event.approxLat;
    final lng = widget.event.approxLng;
    if (lat == null || lng == null) {
      if (mounted) setState(() => _loadingAddress = false);
      return;
    }
    final addr = await getIt<PhotonService>().reverse(lat: lat, lng: lng);
    if (mounted) {
      setState(() {
        _streetAddress = addr;
        _loadingAddress = false;
      });
    }
  }

  String _timeAgo() {
    final ts = widget.event.reportedAt ?? DateTime.now();
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'hace instantes';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar street si está disponible, sino zoneLabel (distrito).
    final displayAddress = _streetAddress ?? widget.event.zoneLabel;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'POR CONFIRMAR · ',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: _loadingAddress
                            ? 'Cargando…'
                            : displayAddress.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0D1B2A),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              '¿Viste un ${widget.event.type.label.toLowerCase()} en esta zona ${_timeAgo()}?',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Sí, vi algo',
                  bg: const Color(0xFFD1FAE5),
                  fg: const Color(0xFF047857),
                  onTap: widget.onSeen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'No vi nada',
                  bg: const Color(0xFFF3F4F6),
                  fg: const Color(0xFF6B7280),
                  onTap: widget.onNotSeen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sheet "¿Sigue ahí?" — confirmar incidente publicado cerca ──────────────

class _NearbyConfirmSheet extends StatelessWidget {
  const _NearbyConfirmSheet({
    required this.incident,
    required this.onStillHere,
    required this.onGone,
  });

  final IncidentEntity incident;
  final VoidCallback onStillHere;
  final VoidCallback onGone;

  Color _severityColor() => switch (incident.severity) {
        Severity.critical => AppColors.severityCritical,
        Severity.moderate => AppColors.severityModerate,
        Severity.low => AppColors.onSurfaceVariant,
      };

  String _severityLabel() => switch (incident.severity) {
        Severity.critical => 'CRÍTICO',
        Severity.moderate => 'MODERADO',
        Severity.low => 'LEVE',
      };

  String _timeAgo() {
    final diff = DateTime.now().difference(incident.createdAt);
    if (diff.inMinutes < 1) return 'hace instantes';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final sev = _severityColor();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Severidad + dirección
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: sev,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _severityLabel(),
                        style: TextStyle(
                          color: sev,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const TextSpan(
                        text: ' · ',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                      ),
                      TextSpan(
                        text: incident.district.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0D1B2A),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tipo · tiempo · conteo
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '${incident.type.label} · Reportado ${_timeAgo()} · ${incident.confirmCount} confirmacion${incident.confirmCount == 1 ? '' : 'es'}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Acciones
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Sigue ahí',
                  bg: const Color(0xFFD1FAE5),
                  fg: const Color(0xFF047857),
                  onTap: onStillHere,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Ya no está',
                  bg: const Color(0xFFF3F4F6),
                  fg: const Color(0xFF6B7280),
                  onTap: onGone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
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
  const _AnimatedReportFab({super.key, required this.onPressed});

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
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
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
                const Icon(Icons.add_alert_outlined,
                    color: AppColors.secondary),
                AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: _extended
                      ? Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              'Reportar incidencias',
                              style: AppTextStyles.labelLg.copyWith(
                                  fontSize: 14,
                                  color: AppColors.mapSurface),
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

// ─── Marcador de la ubicación del usuario (blue dot + halo pulsante) ────────────

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // Más lento que el pin crítico (1400ms) — "vivo" pero no alarmante.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo pulsante exterior
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        // Punto azul sólido con anillo blanco
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.mapSurface, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Pin de la dirección buscada ───────────────────────────────────────────────

class _SearchedLocationPin extends StatelessWidget {
  const _SearchedLocationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.mapSurface, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: AppColors.secondary,
            size: 22,
          ),
        ),
        // Punto-sombra al pie del pin (referencia visual del punto exacto)
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ─── Leyenda de los puntos del mapa ────────────────────────────────────────────

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  static const _items = [
    (AppColors.severityCritical, 'Crítico'),
    (AppColors.severityModerate, 'Moderado'),
    (AppColors.severityLow, 'Leve'),
    (AppColors.primaryContainer, 'Tú'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mapSurface,
      elevation: 4,
      borderRadius: BorderRadius.circular(expanded ? 12 : 999),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(expanded ? 12 : 999),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Padding(
            padding: EdgeInsets.all(expanded ? 12 : 10),
            child: expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Leyenda',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.mapOnSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.close,
                              size: 14, color: AppColors.mapOnSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final (color, label) in _items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.mapOnSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : const Icon(Icons.layers_outlined,
                    size: 22, color: AppColors.primaryContainer),
          ),
        ),
      ),
    );
  }
}

// ─── FAB pequeño para recentrar en la ubicación del usuario ────────────────────

class _RecenterFab extends StatelessWidget {
  const _RecenterFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mapSurface,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.my_location_rounded,
            color: AppColors.primaryContainer,
            size: 22,
          ),
        ),
      ),
    );
  }
}
