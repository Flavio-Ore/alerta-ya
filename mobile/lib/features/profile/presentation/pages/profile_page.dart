import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mi perfil', style: AppTextStyles.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.textMuted, width: 1),
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 40, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Text('Usuario Anónimo', style: AppTextStyles.h2),
                const SizedBox(height: 4),
                const Text('Tu identidad es privada',
                    style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _SectionHeader(label: 'Configuración'),
          _SettingTile(
            icon: Icons.notifications_outlined,
            label: 'Notificaciones push',
            trailing: const _ComingSoonBadge(),
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.language_outlined,
            label: 'Idioma',
            trailing: const _ComingSoonBadge(),
            onTap: () {},
          ),
          const SizedBox(height: 8),
          const _SectionHeader(label: 'Acerca de'),
          _SettingTile(
            icon: Icons.info_outline,
            label: 'Versión 1.0.0',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de privacidad',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthSignOutRequested()),
              icon: const Icon(Icons.logout,
                  color: AppColors.severityCritical, size: 20),
              label: Text(
                'Cerrar sesión',
                style: AppTextStyles.body.copyWith(
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
        ],
      ),
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
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.08,
          ),
        ),
      );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.textSecondary, size: 22),
        title: Text(label, style: AppTextStyles.body),
        trailing: trailing ??
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
        onTap: onTap,
      );
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Próximamente',
          style: AppTextStyles.label.copyWith(color: AppColors.accent),
        ),
      );
}
