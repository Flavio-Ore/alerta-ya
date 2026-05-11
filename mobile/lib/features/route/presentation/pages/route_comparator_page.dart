import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:alertaya/features/route/data/datasources/route_remote_datasource.dart';
import 'package:alertaya/features/route/data/repositories/route_repository_impl.dart';
import 'package:alertaya/features/route/domain/entities/route_option_entity.dart';
import 'package:alertaya/features/route/domain/usecases/compare_routes_usecase.dart';
import 'package:alertaya/features/route/presentation/bloc/route_bloc.dart';

class RouteComparatorPage extends StatefulWidget {
  const RouteComparatorPage({super.key, required this.origin});

  final LatLng origin;

  @override
  State<RouteComparatorPage> createState() => _RouteComparatorPageState();
}

class _RouteComparatorPageState extends State<RouteComparatorPage> {
  late final RouteBloc _routeBloc;
  late final MapController _mapController;
  final _destController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _routeBloc = RouteBloc(
      CompareRoutesUseCase(
        RouteRepositoryImpl(RouteRemoteDatasource()),
      ),
    );
  }

  @override
  void dispose() {
    _routeBloc.close();
    _mapController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void _searchRoute() {
    final query = _destController.text.trim();
    if (query.isEmpty) return;
    final incidentsState = context.read<IncidentsBloc>().state;
    final incidents = incidentsState is IncidentsLoaded
        ? incidentsState.incidents
        : <IncidentEntity>[];
    _routeBloc.add(RouteRequested(
      origin: widget.origin,
      destinationQuery: '$query, Lima, Perú',
      incidents: incidents,
    ));
  }

  void _centerOnRoutes(RouteLoaded state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mid = LatLng(
        (widget.origin.latitude + state.destination.latitude) / 2,
        (widget.origin.longitude + state.destination.longitude) / 2,
      );
      final dist = const Distance()(widget.origin, state.destination);
      final zoom = dist < 1000
          ? 15.0
          : dist < 3000
              ? 14.0
              : dist < 8000
                  ? 13.0
                  : 11.0;
      _mapController.move(mid, zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _routeBloc,
      child: BlocConsumer<RouteBloc, RouteState>(
        listener: (context, state) {
          if (state is RouteLoaded) _centerOnRoutes(state);
        },
        builder: (context, state) => Scaffold(
          backgroundColor: AppColors.dark,
          appBar: AppBar(
            backgroundColor: AppColors.dark,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
            title: Text(
              'Comparador de Rutas',
              style: AppTextStyles.h2.copyWith(color: AppColors.textWhite),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _MapSection(
                      mapController: _mapController,
                      origin: widget.origin,
                      state: state,
                    ),
                    _InputCard(
                      controller: _destController,
                      isLoading: state is RouteLoading,
                      onSubmit: _searchRoute,
                    ),
                  ],
                ),
              ),
              _BottomPanel(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Map section ──────────────────────────────────────────────────────────────

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.mapController,
    required this.origin,
    required this.state,
  });

  final MapController mapController;
  final LatLng origin;
  final RouteState state;

  Color _polylineColor(RouteOptionEntity route) => switch (route.riskScore) {
        <= 30 => AppColors.severityLow,
        <= 60 => AppColors.severityModerate,
        _ => AppColors.severityCritical,
      };

  @override
  Widget build(BuildContext context) {
    final loaded = state is RouteLoaded ? state as RouteLoaded : null;

    final polylines = <Polyline>[];
    final markers = <Marker>[
      Marker(
        point: origin,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
    ];

    if (loaded != null) {
      markers.add(Marker(
        point: loaded.destination,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.severityCritical,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      ));

      for (int i = 0; i < loaded.options.length; i++) {
        final route = loaded.options[i];
        final isSelected = i == loaded.selectedIndex;
        polylines.add(Polyline(
          points: route.polyline,
          color: isSelected
              ? _polylineColor(route)
              : AppColors.textMuted.withValues(alpha: 0.6),
          strokeWidth: isSelected ? 5.0 : 3.0,
        ));
      }

      for (final incident in loaded.selectedOption.nearbyIncidents) {
        markers.add(Marker(
          point: LatLng(incident.lat, incident.lng),
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.severityCritical,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child:
                const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
          ),
        ));
      }
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: origin,
        initialZoom: 14.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.alertaya.app',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

// ─── Input card (floating over the map) ───────────────────────────────────────

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: AppColors.primary, size: 10),
                  Container(
                      width: 1, height: 20, color: AppColors.textMuted),
                  const Icon(Icons.location_on,
                      color: AppColors.severityCritical, size: 16),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tu ubicación actual',
                        style: AppTextStyles.bodySecondary),
                    const SizedBox(height: 4),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Destino...',
                              hintStyle: AppTextStyles.bodySecondary,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: AppTextStyles.body,
                            onSubmitted: (_) => onSubmit(),
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          GestureDetector(
                            onTap: onSubmit,
                            child: const Icon(Icons.search,
                                color: AppColors.textSecondary, size: 20),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom comparison panel ───────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.state});

  final RouteState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Comparar Rutas', style: AppTextStyles.h2),
                  if (state is RouteLoaded)
                    Text(TimeOfDay.now().format(context),
                        style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 16),
              _PanelContent(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({required this.state});

  final RouteState state;

  @override
  Widget build(BuildContext context) {
    if (state is RouteInitial) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.route_outlined, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              'Ingresá un destino para comparar las rutas más seguras',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is RouteLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is RouteFailure) {
      final msg = (state as RouteFailure).message;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.severityCritical),
            const SizedBox(height: 8),
            Text(msg,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<RouteBloc>().add(const RouteReset()),
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      );
    }

    final loaded = state as RouteLoaded;
    final safestRisk = loaded.options
        .map((r) => r.riskScore)
        .reduce((a, b) => a < b ? a : b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (int i = 0; i < loaded.options.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _RouteCard(
                  route: loaded.options[i],
                  isSelected: i == loaded.selectedIndex,
                  isSafest: loaded.options[i].riskScore == safestRisk,
                  onTap: () =>
                      context.read<RouteBloc>().add(RouteOptionSelected(i)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.severityLow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              'Iniciar Ruta ${loaded.selectedOption.label} — La más segura',
              style: AppTextStyles.buttonLabel,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Route option card ─────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.isSelected,
    required this.isSafest,
    required this.onTap,
  });

  final RouteOptionEntity route;
  final bool isSelected;
  final bool isSafest;
  final VoidCallback onTap;

  Color get _riskColor => switch (route.riskScore) {
        <= 30 => AppColors.severityLow,
        <= 60 => AppColors.severityModerate,
        _ => AppColors.severityCritical,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? _riskColor : AppColors.textMuted,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? _riskColor.withValues(alpha: 0.06)
                  : Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ruta ${route.label}',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${route.durationLabel} · ${route.distanceLabel}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: route.riskScore / 100,
                    backgroundColor: AppColors.bgGray,
                    color: _riskColor,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Índice: ${route.riskScore}/100 · ${route.riskLabel}',
                  style: AppTextStyles.label.copyWith(color: _riskColor),
                ),
                if (route.nearbyIncidents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.error_rounded,
                            size: 12,
                            color: AppColors.severityCritical),
                        const SizedBox(width: 3),
                        Text(
                          '${route.nearbyIncidents.length} incidente(s)',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.severityCritical),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isSafest)
            Positioned(
              top: -10,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.severityLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MÁS SEGURA',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
