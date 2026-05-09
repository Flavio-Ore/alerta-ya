import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/realtime/socket_client.dart';
import 'package:alertaya/features/incidents/presentation/bloc/incidents_bloc.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Lima Metropolitana centro — coordenadas de referencia hasta que Anthony integre GPS
  static const double _defaultLat = -12.0464;
  static const double _defaultLng = -77.0428;

  @override
  void initState() {
    super.initState();
    // Conectar socket y cargar incidentes al entrar al mapa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<SocketClient>().connect(lat: _defaultLat, lng: _defaultLng);
      context.read<IncidentsBloc>().add(const IncidentsStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsBloc, IncidentsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bgGray,
          body: Stack(
            children: [
              // TODO(anthony): Reemplazar con flutter_map + marcadores de incidentes
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('Mapa', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    if (state is IncidentsLoaded)
                      Text(
                        '${state.incidents.length} incidente(s) activos',
                        style: AppTextStyles.bodySecondary,
                      )
                    else if (state is IncidentsLoading)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
              // Mini-alert banner — aparece cuando llega un alert:confirm-request
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
