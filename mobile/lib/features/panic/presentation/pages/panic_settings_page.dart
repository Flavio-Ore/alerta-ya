import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:alertaya/features/panic/data/services/trusted_contact_service.dart';
import 'package:alertaya/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:alertaya/features/panic/presentation/pages/panic_page.dart';
import 'package:alertaya/features/profile/presentation/bloc/profile_bloc.dart';

const _kCall105OnLock = 'panic_call_105_on_lock';

class PanicSettingsPage extends StatefulWidget {
  const PanicSettingsPage({super.key});

  @override
  State<PanicSettingsPage> createState() => _PanicSettingsPageState();
}

class _PanicSettingsPageState extends State<PanicSettingsPage> {
  final _contactService = getIt<TrustedContactService>();
  final _deleteAccountUseCase = getIt<DeleteAccountUseCase>();
  final _storage = getIt<SecureStorageService>();

  TrustedContact? _currentContact;
  bool _deletingAccount = false;
  bool _call105OnLock = true;
  bool _hasSavedPin = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
    _loadCall105();
    _loadSavedPin();
  }

  Future<void> _loadSavedPin() async {
    final has = await getIt<PanicBloc>().hasSavedPin();
    if (mounted) setState(() => _hasSavedPin = has);
  }

  Future<void> _loadContact() async {
    final contact = await _contactService.getContact();
    if (mounted) setState(() => _currentContact = contact);
  }

  Future<void> _loadCall105() async {
    final raw = await _storage.read(_kCall105OnLock);
    if (mounted) {
      setState(() => _call105OnLock = raw == null ? true : raw == 'true');
    }
  }

  Future<void> _toggleCall105(bool value) async {
    setState(() => _call105OnLock = value);
    await _storage.write(_kCall105OnLock, value ? 'true' : 'false');
  }

  Future<void> _showPinSetup() async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => PinSetupSheet(
        onConfirm: (p) => Navigator.of(sheetCtx).pop(p),
      ),
    );
    if (pin != null) {
      getIt<PanicBloc>().add(PanicSavedPinUpdated(pin));
      if (mounted) setState(() => _hasSavedPin = true);
    }
  }

  Future<void> _showContactSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ContactSetupSheet(
        initial: _currentContact,
        service: _contactService,
      ),
    );
    if (saved == true) await _loadContact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: const Text('Configuración', style: AppTextStyles.titleLg),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          // ── 1. SEGURIDAD PERSONAL ──────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.shield_outlined,
            label: 'SEGURIDAD PERSONAL',
          ),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.person_add_outlined,
                title: 'Contacto de confianza',
                subtitle: _currentContact == null
                    ? 'Agregar contacto'
                    : '${_currentContact!.name} · ${_maskPhone(_currentContact!.phone)}',
                trailing: _currentContact == null
                    ? const _ChevronRight()
                    : const _Pill(
                        label: 'Configurado',
                        color: AppColors.secondary,
                      ),
                onTap: _showContactSheet,
              ),
              _SettingsItem(
                icon: Icons.pin_outlined,
                title: 'PIN de pánico',
                subtitle: _hasSavedPin
                    ? 'PIN guardado · se usa en cada activación'
                    : 'Sin PIN guardado · se pedirá al activar',
                trailing: _hasSavedPin
                    ? const _Pill(label: 'Configurado', color: AppColors.secondary)
                    : const _Pill(label: 'Al activar', color: AppColors.onSurfaceVariant),
                onTap: _showPinSetup,
              ),
              _SettingsItem(
                icon: Icons.local_police_outlined,
                title: 'Llamar al 105 si me bloquean el PIN',
                subtitle: 'Sugerir llamada de emergencia tras 3 intentos',
                trailing: Switch(
                  value: _call105OnLock,
                  onChanged: _toggleCall105,
                  activeThumbColor: AppColors.secondary,
                ),
              ),
            ],
          ),

          // ── 2. GRABACIÓN Y PRIVACIDAD ──────────────────────────────────────
          const _SectionHeader(
            icon: Icons.mic_outlined,
            label: 'GRABACIÓN Y PRIVACIDAD',
          ),
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              final prefs = state is ProfileData ? state.preferences : null;
              final recordOn = prefs?.panicRecordAudio ?? true;
              final alarmOn = prefs?.panicAlarmSound ?? true;
              return _SettingsGroup(
                children: [
                  _SettingsItem(
                    icon: Icons.mic_none_outlined,
                    title: 'Grabar audio cifrado',
                    subtitle: recordOn
                        ? 'Se graba durante la alarma'
                        : 'No se graba (no recomendado)',
                    trailing: Switch(
                      value: recordOn,
                      onChanged: prefs == null
                          ? null
                          : (val) => context.read<ProfileBloc>().add(
                                ProfilePanicRecordAudioToggled(enabled: val),
                              ),
                      activeThumbColor: AppColors.secondary,
                    ),
                  ),
                  _SettingsItem(
                    icon: alarmOn
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    title: 'Alarma sonora',
                    subtitle: alarmOn
                        ? 'Suena fuerte para disuadir agresores'
                        : 'Modo silencioso — solo grabación y GPS',
                    trailing: Switch(
                      value: alarmOn,
                      onChanged: prefs == null
                          ? null
                          : (val) => context.read<ProfileBloc>().add(
                                ProfilePanicAlarmSoundToggled(enabled: val),
                              ),
                      activeThumbColor: AppColors.secondary,
                    ),
                  ),
                  const _SettingsItem(
                    icon: Icons.location_on_outlined,
                    title: 'GPS en vivo al panel',
                    subtitle: 'Siempre activo — no se puede desactivar',
                    trailing: _Pill(
                      label: 'Obligatorio',
                      color: AppColors.primary,
                    ),
                  ),
                  const _SettingsItem(
                    icon: Icons.timer_outlined,
                    title: 'Grabación máxima',
                    subtitle: '60 minutos en 6 bloques de 10 min',
                    trailing: _Pill(
                      label: '60 min',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const _SettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Cifrado de audio',
                    subtitle: 'Tus grabaciones nunca viajan sin cifrar',
                    trailing: _Pill(
                      label: 'AES-256 ✓',
                      color: AppColors.secondary,
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Eliminar grabaciones anteriores',
                    subtitle: 'Borrar todos los archivos locales encriptados',
                    isDestructive: true,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              );
            },
          ),

          // ── 3. CUENTA ──────────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.account_circle_outlined,
            label: 'CUENTA',
          ),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.delete_outline,
                title: 'Eliminar cuenta',
                subtitle: 'Esta acción es irreversible',
                isDestructive: true,
                trailing: _deletingAccount
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.severityCritical,
                        ),
                      )
                    : const _ChevronRight(),
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
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Eliminar cuenta', style: AppTextStyles.titleLg),
            const SizedBox(height: 10),
            const Text(
              'Esta acción es irreversible. Todos tus datos serán eliminados permanentemente.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.severityCritical,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Eliminar definitivamente',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.severityCritical,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
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
        // Firebase Auth deletion triggers authStateChanges → router redirects to login.
      },
    );
  }
}

String _maskPhone(String phone) {
  final digits = phone.trim();
  if (digits.length < 4) return digits;
  final visibleTail = digits.substring(digits.length - 2);
  final visibleHead = digits.length > 4 ? digits.substring(0, 3) : '';
  return '$visibleHead ** *** *$visibleTail'.trim();
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 32, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Group (sin divisores — gap 12) ─────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ─── Settings Item ────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDestructive ? AppColors.severityCritical : AppColors.onSurface;
    final iconColor =
        isDestructive ? AppColors.severityCritical : AppColors.onSurface;

    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSm.copyWith(color: titleColor),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AppTextStyles.bodySm),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChevronRight extends StatelessWidget {
  const _ChevronRight();

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
        size: 22,
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
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
          const Text('Contacto de confianza', style: AppTextStyles.titleLg),
          const SizedBox(height: 8),
          const Text(
            'Este contacto verá tu ubicación GPS durante una alarma activa y podrás llamarlo con un tap.',
            style: AppTextStyles.bodyMd,
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
            label: 'Teléfono',
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
                backgroundColor: AppColors.primaryContainer,
                disabledBackgroundColor: AppColors.surfaceContainerHighest,
                foregroundColor: AppColors.onPrimaryContainer,
                disabledForegroundColor: AppColors.outline,
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
                        color: AppColors.onPrimaryContainer,
                      ),
                    )
                  : const Text(
                      'Guardar contacto',
                      style: AppTextStyles.labelLg,
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
      style: const TextStyle(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        hintStyle: const TextStyle(color: AppColors.outline),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
