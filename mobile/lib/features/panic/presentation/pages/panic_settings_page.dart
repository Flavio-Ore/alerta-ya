import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';

class PanicSettingsPage extends StatelessWidget {
  const PanicSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Configuración de pánico',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          // ── Seguridad Personal ───────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.shield_outlined,
            label: 'Seguridad Personal',
          ),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.pin,
                label: 'Configurar PIN de desactivación',
                onTap: () => _showComingSoon(context),
              ),
              _SettingsItem(
                icon: Icons.mic_outlined,
                label: 'Palabra clave de voz',
                onTap: () => _showComingSoon(context),
              ),
              _SettingsItem(
                icon: Icons.person_add_outlined,
                label: 'Contacto de confianza',
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Alertas y Notificaciones ─────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.notifications_outlined,
            label: 'Alertas y Notificaciones',
          ),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.radar,
                label: 'Radio de alerta',
                value: '500 m',
                onTap: () => _showComingSoon(context),
              ),
              _SettingsItem(
                icon: Icons.tune,
                label: 'Preferencias de notificación',
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Privacidad ───────────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.lock_outline,
            label: 'Privacidad',
          ),
          _SettingsGroup(
            children: [
              const _SettingsItem(
                icon: Icons.visibility_off_outlined,
                label: 'Anónimo',
                badge: 'Siempre activo',
              ),
              const _SettingsItem(
                icon: Icons.security_outlined,
                label: 'Tus datos cifrados',
                value: 'AES-256 ✓',
              ),
              _SettingsItem(
                icon: Icons.delete_outline,
                label: 'Eliminar cuenta',
                isDestructive: true,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente disponible'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2B3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Esta acción es irreversible. Todos tus datos serán eliminados permanentemente.',
          style: TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.severityCritical,
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    // TODO: dispatch delete account use case
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 15),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 50,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Settings Item ────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.value,
    this.badge,
    this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final String? value;
  final String? badge;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final labelColor = isDestructive ? AppColors.severityCritical : Colors.white;
    final iconColor =
        isDestructive ? AppColors.severityCritical : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.04),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (badge != null) _StatusBadge(label: badge!),
              if (value != null)
                Text(
                  value!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              if (onTap != null && !isDestructive) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.severityLow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.severityLow.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.severityLow,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
