import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import 'package:alertaya/core/widgets/alertaya_card.dart';
import 'package:alertaya/features/panic/data/services/trusted_contact_service.dart';
import 'package:alertaya/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:alertaya/features/profile/presentation/bloc/profile_bloc.dart';

class PanicPage extends StatefulWidget {
  const PanicPage({super.key});

  @override
  State<PanicPage> createState() => _PanicPageState();
}

class _PanicPageState extends State<PanicPage> {
  final _pinController = TextEditingController();
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<PanicBloc>().state;
      if (state is PanicActive) _startTimer(state.session.startedAt);
    });
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onPinChanged() {
    if (mounted) setState(() {});
  }

  void _startTimer(DateTime startedAt) {
    _timer?.cancel();
    _elapsed = DateTime.now().difference(startedAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(startedAt));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _elapsed = Duration.zero;
  }

  Future<void> _onSosTap() async {
    await _requestPanicActivation(_configuredMode());
  }

  /// El botón SOS debe respetar el modo elegido en Ajustes, no forzar alarma
  /// siempre — mismo criterio que usa `_PanicStatusPillsRow` para mostrar el
  /// estado en esta misma pantalla.
  PanicMode _configuredMode() {
    final profileState = context.read<ProfileBloc>().state;
    final prefs = profileState is ProfileData ? profileState.preferences : null;
    return (prefs?.panicAlarmSound ?? true) ? PanicMode.noise : PanicMode.silent;
  }

  Future<void> _onModeSelected(PanicMode mode) async {
    await _requestPanicActivation(mode);
  }

  Future<void> _requestPanicActivation(PanicMode mode) async {
    final hasSaved = await context.read<PanicBloc>().hasSavedPin();
    if (!mounted) return;
    if (hasSaved) {
      await _activatePanic(null, mode);
    } else {
      await _showPinSetupSheet(mode);
    }
  }

  Future<void> _showPinSetupSheet(PanicMode mode) async {
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

    if (pin != null && mounted) {
      await _activatePanic(pin, mode);
    }
  }

  Future<void> _activatePanic(String? pin, PanicMode mode) async {
    double lat = -12.0464;
    double lng = -77.0428;
    bool gpsUnavailable = false;
    bool gpsDeniedForever = false;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = position.latitude;
        lng = position.longitude;
      } else {
        gpsUnavailable = true;
        gpsDeniedForever = permission == LocationPermission.deniedForever;
      }
    } catch (_) {
      gpsUnavailable = true;
    }

    if (gpsUnavailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sin acceso a tu ubicación. Se usará Lima centro como referencia.',
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          action: gpsDeniedForever
              ? const SnackBarAction(
                  label: 'Configuración',
                  textColor: Colors.white,
                  onPressed: Geolocator.openAppSettings,
                )
              : null,
        ),
      );
    }

    if (!mounted) return;
    context.read<PanicBloc>().add(
          PanicActivationRequested(
            lat: lat,
            lng: lng,
            pin: pin,
            mode: mode,
          ),
        );
  }

  void _submitDeactivation() {
    context
        .read<PanicBloc>()
        .add(PanicDeactivationRequested(_pinController.text));
    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final s = context.read<PanicBloc>().state;
        if (s is! PanicActive &&
            s is! PanicActivating &&
            s is! PanicDeactivating) {
          // Usar pop() porque /panic se pushea sobre el shell
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/map');
          }
        }
      },
      child: BlocConsumer<PanicBloc, PanicState>(
        listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        buildWhen: (prev, curr) {
          if (prev is PanicActive && curr is PanicActive) {
            return prev.failedPinAttempts != curr.failedPinAttempts ||
                prev.session != curr.session ||
                prev.isPinLocked != curr.isPinLocked;
          }
          return true;
        },
        listener: (context, state) {
          if (state is PanicActive) {
            _startTimer(state.session.startedAt);
            // Limpiar el PIN después de cada intento fallido
            if (state.failedPinAttempts > 0) {
              _pinController.clear();
            }
          } else {
            _stopTimer();
            _pinController.clear();
          }
          if (state is PanicError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.severityCritical,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PanicActivating || state is PanicDeactivating) {
            return const _LoadingView();
          }
          if (state is PanicActive) {
            return _ActiveView(
              state: state,
              elapsed: _elapsed,
              pinController: _pinController,
              onDeactivate: _submitDeactivation,
            );
          }
          return _IdleView(
            onPanicTap: _onSosTap,
            onModeSelected: _onModeSelected,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/map');
              }
            },
            onSettings: () => context.push('/panic/settings'),
          );
        },
      ),
    );
  }
}

// ─── S09: Idle — SOS Panic Button ────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.onPanicTap,
    required this.onModeSelected,
    required this.onBack,
    required this.onSettings,
  });
  final VoidCallback onPanicTap;
  final ValueChanged<PanicMode> onModeSelected;
  final VoidCallback onBack;
  final VoidCallback onSettings;

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
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: onSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Botón de Pánico',
                      style: AppTextStyles.titleLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mantén presionado 3 segundos para activar',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _PanicHeroButton(onTap: onPanicTap),
                    const SizedBox(height: 20),
                    _PanicModeOptions(onSelected: onModeSelected),
                    const SizedBox(height: 32),
                    const _ComingSoonHint(
                      text: 'o presiona el volumen 3 veces',
                      isComingSoon: false,
                    ),
                    const SizedBox(height: 6),
                    const _ComingSoonHint(text: 'o di tu palabra clave'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _TrustedContactStatusCard(
                onTapWhenEmpty: () => context.push('/panic/settings'),
                onTapWhenSet: () => context.push('/panic/settings'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _PanicStatusPillsRow(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanicHeroButton extends StatefulWidget {
  const _PanicHeroButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PanicHeroButton> createState() => _PanicHeroButtonState();
}

class _PanicHeroButtonState extends State<_PanicHeroButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    const buttonSize = AppConstants.panicScreenButtonDiameter;
    const ringSize = buttonSize + 56;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo punteado decorativo.
          CustomPaint(
            size: const Size(ringSize, ringSize),
            painter: _DashedCirclePainter(
              color: AppColors.severityCritical.withValues(alpha: 0.55),
              strokeWidth: 1.5,
              dashLength: 6,
              gapLength: 8,
            ),
          ),
          GestureDetector(
            onLongPress: widget.onTap,
            onTapDown: (_) => setState(() => _pressing = true),
            onTapUp: (_) => setState(() => _pressing = false),
            onTapCancel: () => setState(() => _pressing = false),
            onLongPressStart: (_) => setState(() => _pressing = true),
            onLongPressEnd: (_) => setState(() => _pressing = false),
            child: AnimatedScale(
              scale: _pressing ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.severityCritical.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppColors.severityCritical,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.severityCritical.withValues(alpha: 0.25),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.severityCritical,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Transform.rotate(
                          angle: -math.pi / 4,
                          child: const Icon(
                            Icons.priority_high_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SOS',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.severityCritical,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanicModeOptions extends StatelessWidget {
  const _PanicModeOptions({required this.onSelected});

  final ValueChanged<PanicMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PanicModeCard(
            icon: Icons.mic_off_outlined,
            title: 'Modo Silencioso',
            subtitle: 'Graba audio y GPS sin sirena',
            onTap: () => onSelected(PanicMode.silent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PanicModeCard(
            icon: Icons.campaign_outlined,
            title: 'Modo con Alarma',
            subtitle: 'Sirena, audio y GPS activos',
            onTap: () => onSelected(PanicMode.noise),
          ),
        ),
      ],
    );
  }
}

class _PanicModeCard extends StatelessWidget {
  const _PanicModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.secondary, size: 26),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Anillo punteado decorativo ──────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashAngle = (dashLength / circumference) * 2 * math.pi;
    final gapAngle = (gapLength / circumference) * 2 * math.pi;

    double start = 0;
    while (start < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashAngle,
        false,
        paint,
      );
      start += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

// ─── Fila de pills de estado (Grabar / Alarma / GPS) ─────────────────────────

class _PanicStatusPillsRow extends StatelessWidget {
  const _PanicStatusPillsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final prefs = state is ProfileData ? state.preferences : null;
        final mode = (prefs?.panicAlarmSound ?? true)
            ? PanicMode.noise
            : PanicMode.silent;
        return Row(
          children: [
            const Expanded(
              child: _PanicStatusPill(
                icon: Icons.mic,
                label: 'Grabar audio',
                iconColor: AppColors.severityCritical,
                enabled: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PanicStatusPill(
                icon: mode.alarmSound
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                label: mode.alarmSound ? 'Alarma sonora' : 'Alarma muda',
                iconColor: AppColors.secondary,
                enabled: mode.alarmSound,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _PanicStatusPill(
                icon: Icons.location_on,
                label: 'GPS en vivo',
                iconColor: AppColors.primary,
                enabled: true,
                locked: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PanicStatusPill extends StatelessWidget {
  const _PanicStatusPill({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.enabled,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool enabled;
  // Si locked, muestra un mini-ícono de candado para indicar "siempre activo, no configurable".
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: enabled ? iconColor : AppColors.onSurfaceVariant,
                  size: 20,
                ),
                if (locked)
                  const Positioned(
                    right: -10,
                    bottom: -2,
                    child: Icon(
                      Icons.lock,
                      color: AppColors.onSurfaceVariant,
                      size: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonHint extends StatelessWidget {
  const _ComingSoonHint({required this.text, this.isComingSoon = true});
  final String text;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        if (isComingSoon) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PRÓXIMAMENTE',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.secondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Card sticky inferior — estado del contacto de confianza (idle screen).
class _TrustedContactStatusCard extends StatelessWidget {
  const _TrustedContactStatusCard({
    required this.onTapWhenEmpty,
    required this.onTapWhenSet,
  });

  final VoidCallback onTapWhenEmpty;
  final VoidCallback onTapWhenSet;

  @override
  Widget build(BuildContext context) {
    final service = getIt<TrustedContactService>();
    return FutureBuilder<TrustedContact?>(
      future: service.getContact(),
      builder: (context, snap) {
        final contact = snap.data;
        final hasContact = contact != null;

        return AlertaYaCard(
          onTap: hasContact ? onTapWhenSet : onTapWhenEmpty,
          child: hasContact
              ? Row(
                  children: [
                    _ContactAvatar(name: contact.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  contact.name,
                                  style: AppTextStyles.titleSm,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ACTIVO',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _maskPhone(contact.phone),
                            style: AppTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Configura un contacto de confianza',
                        style: AppTextStyles.titleSm,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Botón compacto "LLAMAR" con padding reducido para encajar en la card.
class _CallButton extends StatelessWidget {
  const _CallButton({required this.phone, required this.onDial});
  final String phone;
  final VoidCallback onDial;

  @override
  Widget build(BuildContext context) {
    final disabled = phone.trim().isEmpty;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.secondary, AppColors.secondaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          child: InkWell(
            onTap: disabled ? null : onDial,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone,
                      size: 16, color: AppColors.onSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'LLAMAR',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.name, this.size = 40});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.titleMd.copyWith(color: AppColors.onSurface),
      ),
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

// ─── S10: Active Panic Mode ──────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  const _ActiveView({
    required this.state,
    required this.elapsed,
    required this.pinController,
    required this.onDeactivate,
  });

  final PanicActive state;
  final Duration elapsed;
  final TextEditingController pinController;
  final VoidCallback onDeactivate;

  String _formatElapsed(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final locked = state.isPinLocked;
    final attempts = state.failedPinAttempts;
    final block = state.session.currentBlock;
    const maxBlocks =
        AppConstants.panicMaxRecordingMinutes ~/ AppConstants.panicBlockMinutes;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _ActivePanicBanner(),
            Expanded(
              child: Stack(
                children: [
                  // Overlay rojo sutil arriba.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              AppColors.severityCritical
                                  .withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _GpsContactChip(contactName: state.trustedContactName),
                        const SizedBox(height: 24),
                        AlertaYaCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: Column(
                            children: [
                              if (state.mode.recordAudio) ...[
                                const _AmplitudeVisualizer(),
                                const SizedBox(height: 16),
                                const _RecordingLabel(),
                              ] else ...[
                                const _NoRecordingLabel(),
                              ],
                              const SizedBox(height: 12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatElapsed(elapsed),
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontWeight: FontWeight.w200,
                                    fontSize: 64,
                                    color: AppColors.onSurface,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (state.mode.recordAudio) ...[
                              _StatusChip(
                                label: 'Bloque $block/$maxBlocks · 10 min',
                              ),
                              const _StatusChip(label: 'AES-256'),
                            ],
                            const _StatusChip(label: 'GPS en vivo'),
                            if (!state.mode.alarmSound)
                              const _StatusChip(label: 'Sin alarma'),
                            const _StatusChip(label: 'Servidor OK'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _ActiveTrustedContactCard(
                          contactName: state.trustedContactName,
                        ),
                        const SizedBox(height: 20),
                        if (locked)
                          const _PinLockedCard()
                        else
                          _DeactivateCard(
                            controller: pinController,
                            onComplete: onDeactivate,
                            attempts: attempts,
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePanicBanner extends StatefulWidget {
  const _ActivePanicBanner();

  @override
  State<_ActivePanicBanner> createState() => _ActivePanicBannerState();
}

class _ActivePanicBannerState extends State<_ActivePanicBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.severityCritical,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'MODO PÁNICO ACTIVO',
            style: AppTextStyles.labelMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// Label cuando el usuario desactivó la grabación en settings.
// Reemplaza al visualizer + "GRABANDO" en la card del active view.
class _NoRecordingLabel extends StatelessWidget {
  const _NoRecordingLabel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.mic_off_outlined,
          color: AppColors.onSurfaceVariant,
          size: 36,
        ),
        const SizedBox(height: 8),
        Text(
          'SIN GRABACIÓN',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _RecordingLabel extends StatefulWidget {
  const _RecordingLabel();

  @override
  State<_RecordingLabel> createState() => _RecordingLabelState();
}

class _RecordingLabelState extends State<_RecordingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.severityCritical,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'GRABANDO',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.severityCritical,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _ActiveTrustedContactCard extends StatelessWidget {
  const _ActiveTrustedContactCard({required this.contactName});
  final String? contactName;

  @override
  Widget build(BuildContext context) {
    final service = getIt<TrustedContactService>();
    return FutureBuilder<TrustedContact?>(
      future: service.getContact(),
      builder: (context, snap) {
        final contact = snap.data;
        if (contact == null) {
          return AlertaYaCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sin contacto de confianza',
                        style: AppTextStyles.titleSm,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configura uno desde Configuración Personal.',
                        style: AppTextStyles.bodySm,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/panic/settings'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                  ),
                  child: const Text('Configurar'),
                ),
              ],
            ),
          );
        }

        return AlertaYaCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ContactAvatar(name: contact.name, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name, style: AppTextStyles.titleMd),
                        const SizedBox(height: 2),
                        Text(contact.phone, style: AppTextStyles.bodySm),
                      ],
                    ),
                  ),
                  // Botón compacto con padding reducido para caber en la card
                  _CallButton(
                    phone: contact.phone,
                    onDial: () => _dial(context, contact.phone),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: AppColors.severityCritical,
                    size: 8,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      contactName != null
                          ? 'Tu contacto recibió tu ubicación'
                          : 'Compartiendo ubicación…',
                      style: AppTextStyles.bodySm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _dial(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.trim());
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir el dialer del teléfono.'),
        backgroundColor: AppColors.severityCritical,
      ),
    );
  }
}

class _DeactivateCard extends StatelessWidget {
  const _DeactivateCard({
    required this.controller,
    required this.onComplete,
    required this.attempts,
  });

  final TextEditingController controller;
  final VoidCallback onComplete;
  final int attempts;

  @override
  Widget build(BuildContext context) {
    return AlertaYaCard(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARA DESACTIVAR',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _PinDots(
              controller: controller,
              onComplete: onComplete,
            ),
          ),
          if (attempts > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.severityCritical,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'PIN incorrecto · $attempts/${AppConstants.panicPinMaxAttempts} intentos',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.severityCritical,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PinLockedCard extends StatefulWidget {
  const _PinLockedCard();

  @override
  State<_PinLockedCard> createState() => _PinLockedCardState();
}

class _PinLockedCardState extends State<_PinLockedCard> {
  // ponytail: cooldown en UI. El bloqueo real persiste en storage (_kFailedAttempts),
  // así que cerrar la app no lo saltea — solo reinicia esta espera. Subir a cooldown
  // en el BLoC si se necesita que la cuenta atrás sobreviva al cierre.
  Timer? _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = AppConstants.panicPinRetryCooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining - 1).clamp(0, _remaining));
      if (_remaining == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRetry = _remaining == 0;
    return AlertaYaCard(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppColors.secondary,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            'Alarma bloqueada',
            style: AppTextStyles.titleMd,
          ),
          const SizedBox(height: 6),
          Text(
            canRetry
                ? 'Podés reintentar tu PIN, o llama al 105 si estás en peligro.'
                : 'Demasiados intentos. Esperá ${_remaining}s para reintentar tu PIN.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: 20),
          AlertaYaButton(
            label: canRetry ? 'Reintentar PIN' : 'Reintentar en ${_remaining}s',
            icon: Icons.lock_open_outlined,
            variant: AlertaYaButtonVariant.amberGlow,
            onPressed: canRetry
                ? () => context
                    .read<PanicBloc>()
                    .add(const PanicPinRetryRequested())
                : null,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _dial(context, '105'),
            icon: const Icon(Icons.local_police_outlined, size: 18),
            label: const Text('Llamar al 105'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wrapper de amplitud aislado ──────────────────────────────────────────────

class _AmplitudeVisualizer extends StatelessWidget {
  const _AmplitudeVisualizer();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PanicBloc, PanicState, double>(
      selector: (s) => s is PanicActive ? s.amplitude : 0.0,
      builder: (_, amp) => _AudioVisualizer(amplitude: amp),
    );
  }
}

// ─── Visualizador de barras de audio ─────────────────────────────────────────

class _AudioVisualizer extends StatelessWidget {
  const _AudioVisualizer({required this.amplitude});
  final double amplitude;

  static const _barRatios = [0.4, 0.7, 1.0, 0.7, 0.4];

  @override
  Widget build(BuildContext context) {
    const maxHeight = 80.0;
    const minHeight = 12.0;

    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barRatios.length, (i) {
          final height =
              minHeight + (maxHeight - minHeight) * _barRatios[i] * amplitude;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: 14,
            height: height.clamp(minHeight, maxHeight),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.severityCritical,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Dots de PIN ──────────────────────────────────────────────────────────────

class _PinDots extends StatefulWidget {
  const _PinDots({required this.controller, required this.onComplete});
  final TextEditingController controller;
  final VoidCallback onComplete;

  @override
  State<_PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<_PinDots> {
  final _focusNode = FocusNode();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Solo pedir foco si esta ruta es la activa; si PanicPage está detrás de
      // Settings cuando el pánico se activa por volumen, el teclado no debe abrirse.
      // El foco se pedirá cuando Settings haga pop y PanicPage sea la ruta actual.
      if (ModalRoute.of(context)?.isCurrent == true) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == 4 && !_submitted) {
      _submitted = true;
      // Postergar para no ejecutar lógica de negocio dentro del listener.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onComplete();
          // Resetear para permitir reintentos si el PIN fue incorrecto
          _submitted = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TextField invisible — captura el input del teclado sin mostrarse.
        // Opacity(0) oculta cualquier decoración que pueda hacer overflow.
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 1,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              obscureText: true,
              autofocus: true,
              showCursor: false,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            SystemChannels.textInput.invokeMethod('TextInput.show');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isFilled = i < filled;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? AppColors.severityCritical
                      : AppColors.surfaceContainerHighest,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Chip de estado ───────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── GPS Contact Chip ─────────────────────────────────────────────────────────

class _GpsContactChip extends StatelessWidget {
  const _GpsContactChip({required this.contactName});
  final String? contactName;

  @override
  Widget build(BuildContext context) {
    final hasContact = contactName != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.severityCritical.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.severityCritical,
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              hasContact
                  ? 'Compartiendo ubicación con $contactName'
                  : 'Compartiendo ubicación',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.severityCritical,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.severityCritical),
      ),
    );
  }
}

// ─── PIN Setup Sheet (activación) ─────────────────────────────────────────────

class PinSetupSheet extends StatefulWidget {
  const PinSetupSheet({super.key, required this.onConfirm});
  final void Function(String pin) onConfirm;

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<PinSetupSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPinChanged);
    _controller.dispose();
    super.dispose();
  }

  bool _confirmed = false;

  void _onPinChanged() {
    if (mounted) setState(() {});
    if (_controller.text.length == 4 && !_confirmed) {
      _confirmed = true;
      // Postergar el pop fuera del ciclo de notificación del TextEditingController.
      // Hacerlo dentro del listener puede causar errores de renderizado en Samsung.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onConfirm(_controller.text);
      });
    }
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
            'Crear PIN de desactivación',
            style: AppTextStyles.titleLg,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vas a necesitar este PIN de 4 dígitos para detener la alarma.',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            autofocus: true,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 36,
              letterSpacing: 20,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: '••••',
              hintStyle: const TextStyle(
                color: AppColors.outline,
                fontSize: 36,
                letterSpacing: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
