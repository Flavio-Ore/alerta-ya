import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/map/domain/entities/incident_entity.dart';
import 'package:alertaya/features/map/presentation/bloc/map_bloc.dart';
import 'incident_detail_sheet.dart';

// Centro de Lima — R01 CONSTRAINTS.md
const _limaCenter = LatLng(-12.0464, -77.0428);

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    context.read<MapBloc>().add(const MapLoadRequested());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return Stack(
            children: [
              // ── Mapa base ──────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _limaCenter,
                  initialZoom: 13,
                  minZoom: 11,
                  maxZoom: 18,
                  onTap: (_, __) => context
                      .read<MapBloc>()
                      .add(const MapIncidentDeselected()),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.alertaya',
                  ),
                  if (state is MapLoaded)
                    MarkerLayer(
                      markers: state.incidents
                          .map((i) => _buildMarker(context, i,
                              isSelected: state.selectedIncident?.id == i.id))
                          .toList(),
                    ),
                ],
              ),

              // ── Header flotante ────────────────────────────────
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MapHeader(),
                      const SizedBox(height: 10),
                      _SearchBar(),
                      const SizedBox(height: 8),
                      if (state is MapLoaded && state.zoneSeverity != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _ZoneChip(severity: state.zoneSeverity!),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Loading ────────────────────────────────────────
              if (state is MapLoading)
                const Center(child: CircularProgressIndicator()),

              // ── Error ──────────────────────────────────────────
              if (state is MapError)
                Positioned(
                  bottom: 100,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.severityCritical,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (state).message,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // ── Bottom sheet de incidente seleccionado ─────────
              if (state is MapLoaded && state.selectedIncident != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IncidentDetailSheet(
                    incident: state.selectedIncident!,
                    onConfirm: (stillHere) {
                      context.read<MapBloc>().add(MapIncidentConfirmed(
                            incidentId: state.selectedIncident!.id,
                            stillHere: stillHere,
                          ));
                    },
                  ),
                ),
            ],
          );
        },
      ),
      // FAB de reporte — NAVIGATION.md: visible solo en S04
      floatingActionButton: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) => state is MapLoaded
            ? FloatingActionButton(
                onPressed: () => context.push('/report/type'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tooltip: 'Reportar incidente',
                child: const Icon(Icons.add, size: 28),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Marker _buildMarker(
    BuildContext context,
    IncidentEntity incident, {
    bool isSelected = false,
  }) {
    // Tamaños según UI_RULES.md
    final size = switch (incident.severity) {
          Severity.low => 24.0,
          Severity.moderate => 28.0,
          Severity.critical => 32.0,
        } *
        (isSelected ? 1.2 : 1.0);

    final color = switch (incident.severity) {
      Severity.low => AppColors.severityLow,
      Severity.moderate => AppColors.severityModerate,
      Severity.critical => AppColors.severityCritical,
    };

    return Marker(
      point: LatLng(incident.lat, incident.lng),
      width: size + 12,
      height: size + 12,
      child: GestureDetector(
        onTap: () => context.read<MapBloc>().add(MapIncidentSelected(incident)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // Anillo pulsante solo en CRÍTICO — UI_RULES.md
            border: incident.severity == Severity.critical
                ? Border.all(
                    color: AppColors.severityCritical.withValues(alpha: 0.4),
                    width: 4,
                  )
                : null,
          ),
          child: Icon(
            Icons.bolt,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

// ── Widgets del header ─────────────────────────────────────────────

class _MapHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'Alerta',
            style: AppTextStyles.logoAlerta.copyWith(fontSize: 18),
          ),
          Text(
            'Ya',
            style: AppTextStyles.logoYa.copyWith(fontSize: 18),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined,
                  color: AppColors.textPrimary, size: 24),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.severityCritical,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Text(
            'Buscar dirección o zona...',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.severity});
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      Severity.low => AppColors.severityLow,
      Severity.moderate => AppColors.severityModerate,
      Severity.critical => AppColors.severityCritical,
    };
    final label = switch (severity) {
      Severity.low => 'LEVE',
      Severity.moderate => 'MODERADO',
      Severity.critical => 'CRÍTICO',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
            'Zona: $label',
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
