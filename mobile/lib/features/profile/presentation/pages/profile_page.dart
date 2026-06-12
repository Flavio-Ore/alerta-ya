import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:alertaya/features/profile/presentation/bloc/profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                      _ReputationBadge(score: state.profile.reputationScore),
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
              const _SectionHeader(label: 'Notificaciones'),
              if (state is ProfileData) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined,
                      color: AppColors.onSurfaceVariant),
                  title: const Text('Alertas push',
                      style: AppTextStyles.bodyLg),
                  subtitle: const Text('Incidentes en tu zona',
                      style: AppTextStyles.bodyMd),
                  value: !state.preferences.muteNotifications,
                  activeThumbColor: AppColors.secondary,
                  onChanged: (val) => context.read<ProfileBloc>().add(
                        ProfileMuteToggled(mute: !val),
                      ),
                ),
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
                  icon: Icons.notifications_outlined,
                  label: 'Alertas push',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.radar_outlined,
                  label: 'Radio de alertas',
                  onTap: () {},
                ),
              ],

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
              'Recibís alertas de incidentes dentro de este radio.',
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
  const _ReputationBadge({required this.score});
  final int score;

  Color get _color {
    if (score >= 80) return AppColors.secondary;
    if (score >= 50) return AppColors.severityModerate;
    return AppColors.severityCritical;
  }

  @override
  Widget build(BuildContext context) => Container(
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
              'Reputación: $score',
              style: AppTextStyles.labelMd.copyWith(color: _color),
            ),
          ],
        ),
      );
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
