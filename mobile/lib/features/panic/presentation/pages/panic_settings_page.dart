import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:alertaya/features/panic/data/services/trusted_contact_service.dart';

class PanicSettingsPage extends StatefulWidget {
  const PanicSettingsPage({super.key});

  @override
  State<PanicSettingsPage> createState() => _PanicSettingsPageState();
}

class _PanicSettingsPageState extends State<PanicSettingsPage> {
  final _contactService = getIt<TrustedContactService>();
  final _deleteAccountUseCase = getIt<DeleteAccountUseCase>();
  TrustedContact? _currentContact;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    final contact = await _contactService.getContact();
    if (mounted) setState(() => _currentContact = contact);
  }

  Future<void> _showContactSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2B3B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ContactSetupSheet(
        initial: _currentContact,
        service: _contactService,
      ),
    );
    if (saved == true) _loadContact();
  }

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
                value: _currentContact?.name,
                onTap: _showContactSheet,
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
                onTap: _deletingAccount ? null : () => _confirmDelete(context),
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

  Future<void> _confirmDelete(BuildContext context) async {
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

    setState(() => _deletingAccount = true);
    final result = await _deleteAccountUseCase();
    if (!context.mounted) return;

    result.fold(
      (failure) {
        setState(() => _deletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar la cuenta. Intentá de nuevo.'),
            backgroundColor: AppColors.severityCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        // Firebase Auth deletion triggers authStateChanges → router redirects to login
      },
    );
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

// ─── Contact Setup Sheet ──────────────────────────────────────────────────────

class _ContactSetupSheet extends StatefulWidget {
  const _ContactSetupSheet({required this.initial, required this.service});
  final TrustedContact? initial;
  final TrustedContactService service;

  @override
  State<_ContactSetupSheet> createState() => _ContactSetupSheetState();
}

class _ContactSetupSheetState extends State<_ContactSetupSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.initial?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    await widget.service.saveContact(
      TrustedContact(name: _nameCtrl.text, phone: _phoneCtrl.text),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _clear() async {
    await widget.service.clearContact();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 32, 24, 32 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contacto de confianza',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Este contacto verá tu ubicación GPS durante una alarma activa.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _ContactField(
            controller: _nameCtrl,
            label: 'Nombre',
            hint: 'Ej: Mamá',
            icon: Icons.person_outline,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _ContactField(
            controller: _phoneCtrl,
            label: 'Teléfono (opcional)',
            hint: 'Ej: +51 999 123 456',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isValid && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Guardar contacto',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          if (widget.initial != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _clear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.severityCritical,
                ),
                child: const Text('Eliminar contacto'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
