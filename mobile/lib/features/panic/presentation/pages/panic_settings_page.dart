import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:alertaya/features/panic/data/services/panic_channel_service.dart';
import 'package:alertaya/features/panic/data/services/trusted_contact_service.dart';
import 'package:alertaya/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:alertaya/features/panic/presentation/pages/panic_page.dart';
import 'package:alertaya/features/profile/presentation/bloc/profile_bloc.dart';

const _kCall105OnLock = 'panic_call_105_on_lock';
const _kSendSms = 'panic_send_sms';
const _kRecordVideo = 'panic_record_video';
const _kRecordAudio = 'panic_record_audio';
const _kAlarmSound = 'panic_alarm_sound';
const _kVolumeActivation = 'panic_volume_activation';

// ─── Modo de emergencia ───────────────────────────────────────────────────────

enum _PanicMode {
  visible,
  silencioso,
  combinado;

  /// Deriva el modo desde las preferencias almacenadas.
  /// Requiere los tres valores porque Visible y Combinado tienen alarm=true.
  static _PanicMode fromPrefs({
    required bool alarm,
    required bool record,
    required bool video,
  }) {
    if (!alarm && record) return _PanicMode.silencioso;
    if (alarm && video) return _PanicMode.combinado;
    return _PanicMode.visible;
  }

  String get label => switch (this) {
        _PanicMode.visible => 'Visible',
        _PanicMode.silencioso => 'Silencioso',
        _PanicMode.combinado => 'Combinado',
      };

  String get description => switch (this) {
        _PanicMode.visible =>
          'Alarma sonora máxima. Para cuando quieras llamar la atención.',
        _PanicMode.silencioso =>
          'Sin alarma ni vibración. Grabación de audio cifrada. Discreción total.',
        _PanicMode.combinado =>
          'Alarma + grabación de video. Captura video del entorno como evidencia.',
      };

  IconData get icon => switch (this) {
        _PanicMode.visible => Icons.campaign_outlined,
        _PanicMode.silencioso => Icons.visibility_off_outlined,
        _PanicMode.combinado => Icons.videocam_outlined,
      };

  // audio activo solo en Silencioso
  bool get derivedAlarm => this != _PanicMode.silencioso;
  bool get derivedRecord => this == _PanicMode.silencioso;
  // video activo solo en Combinado
  bool get derivedVideo => this == _PanicMode.combinado;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class PanicSettingsPage extends StatefulWidget {
  const PanicSettingsPage({super.key});

  @override
  State<PanicSettingsPage> createState() => _PanicSettingsPageState();
}

class _PanicSettingsPageState extends State<PanicSettingsPage> {
  final _contactService = getIt<TrustedContactService>();
  final _deleteAccountUseCase = getIt<DeleteAccountUseCase>();
  final _storage = getIt<SecureStorageService>();
  final _channelService = getIt<PanicChannelService>();

  TrustedContact? _currentContact;
  bool _deletingAccount = false;
  bool _call105OnLock = true;
  bool _sendSms = true;
  bool _recordVideo = false;
  bool _volumeActivation = true;
  bool _hasSavedPin = false;
  bool _accessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
    _loadCall105();
    _loadSendSms();
    _loadRecordVideo();
    _loadVolumeActivation();
    _loadSavedPin();
    _loadAccessibilityStatus();
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

  Future<void> _loadSendSms() async {
    final raw = await _storage.read(_kSendSms);
    if (mounted) setState(() => _sendSms = raw != 'false');
  }

  Future<void> _loadRecordVideo() async {
    final raw = await _storage.read(_kRecordVideo);
    if (mounted) setState(() => _recordVideo = raw == 'true');
  }

  Future<void> _loadVolumeActivation() async {
    final raw = await _storage.read(_kVolumeActivation);
    if (mounted) setState(() => _volumeActivation = raw != 'false');
  }

  Future<void> _loadAccessibilityStatus() async {
    if (!Platform.isAndroid) return;
    final enabled = await _channelService.isAccessibilityServiceEnabled();
    if (mounted) setState(() => _accessibilityEnabled = enabled);
  }

  Future<void> _toggleVolumeActivation(bool value) async {
    setState(() => _volumeActivation = value);
    await _storage.write(_kVolumeActivation, value ? 'true' : 'false');
  }

  Future<void> _toggleCall105(bool value) async {
    setState(() => _call105OnLock = value);
    await _storage.write(_kCall105OnLock, value ? 'true' : 'false');
  }

  Future<void> _toggleSendSms(bool value) async {
    setState(() => _sendSms = value);
    await _storage.write(_kSendSms, value ? 'true' : 'false');
  }

  Future<void> _onModeSelected(_PanicMode mode, BuildContext context) async {
    context.read<ProfileBloc>().add(
          ProfilePanicRecordAudioToggled(enabled: mode.derivedRecord),
        );
    context.read<ProfileBloc>().add(
          ProfilePanicAlarmSoundToggled(enabled: mode.derivedAlarm),
        );
    // Escribir en SecureStorage para que la activación por botón de volumen
    // (que no tiene acceso al ProfileBloc) lea el modo correcto incluso si
    // el usuario nunca activó pánico antes.
    await Future.wait([
      _storage.write(_kRecordAudio, mode.derivedRecord.toString()),
      _storage.write(_kAlarmSound, mode.derivedAlarm.toString()),
      _storage.write(_kRecordVideo, mode.derivedVideo.toString()),
    ]);
    if (mounted) setState(() => _recordVideo = mode.derivedVideo);
  }

  Future<void> _deleteRecordings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Eliminar grabaciones', style: AppTextStyles.titleLg),
        content: const Text(
          'Se borrarán todos los archivos de audio cifrados almacenados localmente en este dispositivo.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.severityCritical),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final entities = await dir.list().toList();
    int count = 0;
    for (final e in entities) {
      if (e is File &&
          e.path.contains('panic_') &&
          e.path.endsWith('_enc.bin')) {
        await e.delete();
        count++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'No hay grabaciones locales almacenadas'
                : '$count archivo${count == 1 ? '' : 's'} eliminado${count == 1 ? '' : 's'}',
          ),
          backgroundColor: AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          // ── 0. MODO DE EMERGENCIA ──────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.emergency_outlined,
            label: 'MODO DE EMERGENCIA',
          ),
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              final prefs = state is ProfileData ? state.preferences : null;
              final alarm = prefs?.panicAlarmSound ?? true;
              final record = prefs?.panicRecordAudio ?? true;
              final currentMode = _PanicMode.fromPrefs(
                alarm: alarm,
                record: record,
                video: _recordVideo,
              );
              return Column(
                children: [
                  for (int i = 0; i < _PanicMode.values.length; i++) ...[
                    _ModeCard(
                      mode: _PanicMode.values[i],
                      selected: currentMode == _PanicMode.values[i],
                      onTap: prefs == null
                          ? null
                          : () {
                              _onModeSelected(_PanicMode.values[i], context);
                            },
                    ),
                    if (i < _PanicMode.values.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),

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
                icon: Icons.sms_outlined,
                title: 'Enviar SMS al activar',
                subtitle: _sendSms
                    ? 'Notifica a tu contacto de confianza al activar'
                    : 'No se enviará SMS automático',
                trailing: Switch(
                  value: _sendSms,
                  onChanged: _toggleSendSms,
                  activeThumbColor: AppColors.secondary,
                ),
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
              _SettingsItem(
                icon: Icons.volume_up_outlined,
                title: 'Activar con botón de volumen',
                subtitle: _volumeActivation
                    ? 'Presiona el volumen 3 veces en < 2 seg para activar'
                    : 'Desactivado — solo el botón en pantalla activa el pánico',
                trailing: Switch(
                  value: _volumeActivation,
                  onChanged: _toggleVolumeActivation,
                  activeThumbColor: AppColors.secondary,
                ),
              ),
              if (_volumeActivation && Platform.isAndroid)
                _AccessibilityServiceTile(
                  enabled: _accessibilityEnabled,
                  onTap: () async {
                    await _channelService.openAccessibilitySettings();
                    // Re-verificar al volver de Settings del sistema
                    await Future<void>.delayed(const Duration(seconds: 1));
                    await _loadAccessibilityStatus();
                  },
                ),
            ],
          ),

          // ── 2. GRABACIÓN Y PRIVACIDAD ──────────────────────────────────────
          const _SectionHeader(
            icon: Icons.mic_outlined,
            label: 'GRABACIÓN Y PRIVACIDAD',
          ),
          _SettingsGroup(
            children: [
              const _SettingsItem(
                icon: Icons.location_on_outlined,
                title: 'GPS en vivo al panel',
                subtitle: 'Siempre activo en cualquier modo — no se puede desactivar',
                trailing: _Pill(
                  label: 'Obligatorio',
                  color: AppColors.primary,
                ),
              ),
              const _SettingsItem(
                icon: Icons.timer_outlined,
                title: 'Límites de grabación',
                subtitle: 'Audio: 60 min (6 bloques de 10 min) · Video: 20 min (10 clips de 2 min)',
                trailing: _Pill(
                  label: 'Por modo',
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const _SettingsItem(
                icon: Icons.lock_outline,
                title: 'Cifrado de grabaciones',
                subtitle: 'Audio y video cifrados con AES-256 — nunca viajan sin cifrar',
                trailing: _Pill(
                  label: 'AES-256 ✓',
                  color: AppColors.secondary,
                ),
              ),
              _SettingsItem(
                icon: Icons.delete_sweep_outlined,
                title: 'Eliminar grabaciones anteriores',
                subtitle: 'Borrar todos los archivos cifrados almacenados en este dispositivo',
                isDestructive: true,
                onTap: () => _deleteRecordings(context),
              ),
            ],
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
            content: Text('No se pudo eliminar la cuenta. Intenta de nuevo.'),
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

// ─── Mode Card ────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    this.onTap,
  });

  final _PanicMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.secondary.withValues(alpha: 0.08)
          : AppColors.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? const BorderSide(color: AppColors.secondary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                mode.icon,
                color: selected ? AppColors.secondary : AppColors.onSurface,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: AppTextStyles.titleSm.copyWith(
                        color:
                            selected ? AppColors.secondary : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(mode.description, style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.secondary : AppColors.outline,
                size: 20,
              ),
            ],
          ),
        ),
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

// ─── Accessibility Service Tile ───────────────────────────────────────────────

class _AccessibilityServiceTile extends StatelessWidget {
  const _AccessibilityServiceTile({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.secondary.withValues(alpha: 0.06)
          : AppColors.severityModerate.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                enabled
                    ? Icons.accessibility_new
                    : Icons.warning_amber_rounded,
                color: enabled ? AppColors.secondary : AppColors.severityModerate,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled
                          ? 'Activación en background habilitada'
                          : 'Solo funciona con la app abierta',
                      style: AppTextStyles.titleSm.copyWith(
                        color: enabled
                            ? AppColors.secondary
                            : AppColors.severityModerate,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enabled
                          ? 'El servicio de accesibilidad detecta el triple pulsación incluso con la app cerrada.'
                          : 'Activa el servicio de accesibilidad de AlertaYa para que funcione en cualquier momento.',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              if (!enabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.severityModerate.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Activar',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.severityModerate,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
