import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/services/fcm_service.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:alertaya/features/profile/domain/entities/user_profile_entity.dart';
import 'package:alertaya/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:alertaya/features/tutorial/presentation/service/tutorial_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Carga el perfil al abrir la página por primera vez.
    _refreshProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresca el perfil cuando la app vuelve al primer plano
    // (p.ej. después de volver desde el flujo de reporte).
    if (state == AppLifecycleState.resumed) _refreshProfile();
  }

  void _refreshProfile() {
    if (!mounted) return;
    context.read<ProfileBloc>().add(const ProfileLoaded());
  }

  @override
  Widget build(BuildContext context) {
    // ProfileBloc se provee globalmente en AlertaYaApp.
    return const _ProfileView();
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mi perfil', style: AppTextStyles.headlineMd),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // ── Avatar anónimo + reputación (API)
              // SECURITY: no se renderiza displayName ni photoURL — la identidad
              // del ciudadano es privada (ver docs/rules/SECURITY_RULES.md).
              Center(
                child: Column(
                  children: [
                    const _AvatarWidget(),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu identidad es privada',
                      style: AppTextStyles.bodyMd,
                    ),
                    const SizedBox(height: 12),
                    // Reputación — solo si cargó
                    if (state is ProfileData) ...[
                      _ReputationBadge(
                        score: state.profile.reputationScore,
                        tier: state.profile.tier,
                        pointsToNext: state.profile.pointsToNext,
                      ),
                    ] else if (state is ProfileLoading) ...[
                      const SizedBox(
                        width: 80,
                        height: 24,
                        child: LinearProgressIndicator(
                            color: AppColors.secondary),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Notificaciones
              // El permiso del SO es local — siempre se muestra independientemente
              // de si la API cargó. El toggle de silenciar solo aparece con datos.
              const _SectionHeader(label: 'Notificaciones'),
              _NotificationPermissionTile(
                preferences: state is ProfileData ? state.preferences : null,
                onMuteToggled: state is ProfileData
                    ? (val) => context.read<ProfileBloc>().add(
                          ProfileMuteToggled(mute: !val),
                        )
                    : null,
              ),
              if (state is ProfileData) ...[
                ListTile(
                  leading: const Icon(Icons.radar_outlined,
                      color: AppColors.onSurfaceVariant),
                  title: const Text('Radio de alertas',
                      style: AppTextStyles.bodyLg),
                  subtitle: Text(
                    _radiusLabel(state.preferences.alertRadiusMeters),
                    style: AppTextStyles.bodyMd,
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.onSurfaceVariant, size: 20),
                  onTap: () => _showRadiusPicker(context, state.preferences.alertRadiusMeters),
                ),
              ] else ...[
                _SettingTile(
                  icon: Icons.radar_outlined,
                  label: 'Radio de alertas',
                  onTap: () {},
                ),
              ],

              const SizedBox(height: 8),

              // ── Tutorial
              const _SectionHeader(label: 'Tutorial'),
              _SettingTile(
                icon: Icons.help_outline_rounded,
                label: 'Ver tutorial de nuevo',
                onTap: () async {
                  // Resetea el flag y navega al mapa; AppShell.didUpdateWidget
                  // detectará el cambio de branch y disparará maybeStart.
                  await getIt<TutorialService>().prepareManualRestart();
                  if (context.mounted) context.go('/map');
                },
              ),

              const SizedBox(height: 8),

              // ── Cuenta
              const _SectionHeader(label: 'Cuenta'),
              if (state is ProfileData)
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined,
                      color: AppColors.onSurfaceVariant, size: 20),
                  title: const Text('Miembro desde',
                      style: AppTextStyles.bodyLg),
                  subtitle: Text(
                    _formatDate(state.profile.memberSince),
                    style: AppTextStyles.bodyMd,
                  ),
                ),
              _SettingTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Política de privacidad',
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.info_outline,
                label: 'Versión 1.0.0',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // ── Cerrar sesión
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const AuthSignOutRequested()),
                  icon: const Icon(Icons.logout,
                      color: AppColors.severityCritical, size: 20),
                  label: Text(
                    'Cerrar sesión',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.severityCritical,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.severityCritical),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _radiusLabel(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDate(DateTime date) {
    return '${_month(date.month)} ${date.year}';
  }

  String _month(int m) => const [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ][m];

  void _showRadiusPicker(BuildContext context, int currentMeters) {
    const options = [500, 1000, 2000, 5000, 10000];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Radio de alertas', style: AppTextStyles.titleLg),
            const SizedBox(height: 4),
            const Text(
              'Recibirás alertas de incidentes dentro de este radio.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: 16),
            ...options.map((m) {
                  final selected = m == currentMeters;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AppColors.secondary
                          : AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                    title: Text(
                      m < 1000 ? '$m m' : '${(m / 1000).toStringAsFixed(1)} km',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: selected ? AppColors.secondary : null,
                      ),
                    ),
                    onTap: () {
                      context.read<ProfileBloc>().add(
                            ProfileAlertRadiusChanged(meters: m),
                          );
                      Navigator.pop(ctx);
                    },
                  );
                }),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

// Tile de "Alertas push" que refleja el permiso real del SO.
// Si el permiso no está concedido, guía al usuario a la configuración del sistema.
// Si está concedido, muestra el toggle de silenciar/activar.
// Refresca el estado del permiso cada vez que la app vuelve al primer plano.
class _NotificationPermissionTile extends StatefulWidget {
  const _NotificationPermissionTile({
    required this.preferences,
    required this.onMuteToggled,
  });

  // Null cuando la API no cargó — el permiso del SO funciona igual,
  // pero el toggle de silenciar queda deshabilitado.
  final UserPreferencesEntity? preferences;
  final ValueChanged<bool>? onMuteToggled;

  @override
  State<_NotificationPermissionTile> createState() =>
      _NotificationPermissionTileState();
}

class _NotificationPermissionTileState
    extends State<_NotificationPermissionTile> with WidgetsBindingObserver {
  // null = todavía resolviendo; evita mostrar "Permiso desactivado" antes de saber el estado real.
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final previous = _status;
    final current = await Permission.notification.status;
    if (!mounted) return;
    setState(() => _status = current);
    // Si el usuario acaba de conceder el permiso desde ajustes del SO,
    // registrar el token FCM que no se pudo registrar antes.
    if (previous != null && !previous.isGranted && current.isGranted) {
      unawaited(getIt<FcmService>().registerToken());
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    // Cargando — tile esqueleto sin acción para no confundir al usuario.
    if (status == null) {
      return ListTile(
        leading: const Icon(Icons.notifications_outlined,
            color: AppColors.onSurfaceVariant),
        title: const Text('Alertas push', style: AppTextStyles.bodyLg),
        subtitle: const Text('Incidentes en tu zona',
            style: AppTextStyles.bodyMd),
        trailing: SizedBox(
          width: 36,
          height: 20,
          child: LinearProgressIndicator(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.outline.withValues(alpha: 0.4),
            backgroundColor: Colors.transparent,
          ),
        ),
      );
    }

    if (!status.isGranted) {
      return ListTile(
        leading: const Icon(Icons.notifications_off_outlined,
            color: AppColors.onSurfaceVariant),
        title: const Text('Alertas push', style: AppTextStyles.bodyLg),
        subtitle: const Text('Permiso desactivado · Tocá para activar',
            style: AppTextStyles.bodyMd),
        trailing: const Icon(Icons.open_in_new,
            color: AppColors.onSurfaceVariant, size: 18),
        onTap: () => openAppSettings(),
      );
    }

    final prefs = widget.preferences;
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_outlined,
          color: AppColors.onSurfaceVariant),
      title: const Text('Alertas push', style: AppTextStyles.bodyLg),
      subtitle: const Text('Incidentes en tu zona', style: AppTextStyles.bodyMd),
      value: prefs != null ? !prefs.muteNotifications : true,
      activeThumbColor: AppColors.secondary,
      onChanged: widget.onMuteToggled,
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: const Icon(Icons.person_outline,
          size: 40, color: AppColors.onSurfaceVariant),
    );
  }
}

class _ReputationBadge extends StatelessWidget {
  const _ReputationBadge({
    required this.score,
    this.tier,
    this.pointsToNext,
  });
  final int score;

  /// Nivel de reputación ('high'|'medium'|'low'). Null = API vieja, sin nivel.
  final String? tier;

  /// Puntos que faltan para subir de nivel. Solo se muestra si no es null.
  final int? pointsToNext;

  Color get _color {
    if (score >= 80) return AppColors.secondary;
    if (score >= 50) return AppColors.severityModerate;
    return AppColors.severityCritical;
  }

  String? get _tierLabel => switch (tier) {
        'high' => 'Confiable',
        'medium' => 'Habitual',
        'low' => 'Nuevo',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final tierLabel = _tierLabel;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 14, color: _color),
              const SizedBox(width: 5),
              Text(
                tierLabel != null
                    ? 'Reputación: $score · $tierLabel'
                    : 'Reputación: $score',
                style: AppTextStyles.labelMd.copyWith(color: _color),
              ),
            ],
          ),
        ),
        if (pointsToNext != null) ...[
          const SizedBox(height: 4),
          Text(
            'Faltan $pointsToNext pts para subir de nivel',
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.08,
          ),
        ),
      );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
        title: Text(label, style: AppTextStyles.bodyLg),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.outline, size: 20),
        onTap: onTap,
      );
}
