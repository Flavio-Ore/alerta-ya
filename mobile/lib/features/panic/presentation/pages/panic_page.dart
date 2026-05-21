import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/features/panic/presentation/bloc/panic_bloc.dart';

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

  Future<void> _showPinSetupSheet() async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _PinSetupSheet(
        onConfirm: (p) => Navigator.of(sheetCtx).pop(p),
      ),
    );

    // Activar DESPUÉS de que el sheet esté cerrado y solo si esta página
    // sigue montada. El controller del sheet vive y muere dentro del sheet.
    if (pin != null && mounted) {
      await _activatePanic(pin);
    }
  }

  Future<void> _activatePanic(String pin) async {
    double lat = -12.0464;
    double lng = -77.0428;
    bool gpsUnavailable = false;
    bool gpsDeniedForever = false;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
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
          backgroundColor: AppColors.accent,
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

    // Solicitar permiso de micrófono antes de iniciar el servicio
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Se necesita permiso de micrófono para activar el pánico'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    context.read<PanicBloc>().add(
          PanicActivationRequested(lat: lat, lng: lng, pin: pin),
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
          context.go('/map');
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
            onPanicTap: _showPinSetupSheet,
            onBack: () => context.go('/map'),
            onSettings: () => context.push('/panic/settings'),
          );
        },
      ),
    );
  }
}

// ─── S09: Idle ────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.onPanicTap,
    required this.onBack,
    required this.onSettings,
  });
  final VoidCallback onPanicTap;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'BOTÓN DE PÁNICO',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 52),
                  GestureDetector(
                    onTap: onPanicTap,
                    child: Container(
                      width: AppConstants.panicScreenButtonDiameter,
                      height: AppConstants.panicScreenButtonDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.severityCritical,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.severityCritical.withAlpha(100),
                            blurRadius: 48,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_rounded,
                              color: Colors.white, size: 56),
                          SizedBox(height: 8),
                          Text(
                            'PÁNICO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 52),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Activa una alarma de emergencia y comparte tu ubicación.\n'
                      'Necesitarás un PIN de 4 dígitos para desactivarla.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textSecondary),
                onPressed: onBack,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textSecondary),
                onPressed: onSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── S10: Active ──────────────────────────────────────────────────────────────

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
      backgroundColor: const Color(0xFF1A0000),
      body: SafeArea(
        child: Column(
          children: [
            // ── Banner superior MODO PÁNICO ACTIVO ──────────────
            Container(
              width: double.infinity,
              color: AppColors.severityCritical,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 8),
                  Text(
                    'MODO PÁNICO ACTIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Chip GPS compartido ──────────────────────
                    _GpsContactChip(contactName: state.trustedContactName),

                    const SizedBox(height: 32),

                    // ── Visualizador de audio ────────────────────
                    const _AmplitudeVisualizer(),

                    const SizedBox(height: 16),

                    // ── Label GRABANDO ───────────────────────────
                    const Text(
                      'GRABANDO',
                      style: TextStyle(
                        color: AppColors.severityCritical,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Timer ────────────────────────────────────
                    Text(
                      _formatElapsed(elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w200,
                        fontFeatures: [FontFeature.tabularFigures()],
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Chips de estado ──────────────────────────
                    Wrap(
                      spacing: 8,
                      children: [
                        _StatusChip(label: 'Bloque $block/$maxBlocks · 10 min'),
                        const _StatusChip(label: 'AES-256 cifrado'),
                        const _StatusChip(label: 'SERVIDOR OK'),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Sección desactivar ───────────────────────
                    if (!locked) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PARA DESACTIVAR:',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PinDots(
                              controller: pinController,
                              onComplete: onDeactivate,
                            ),
                            if (attempts > 0) ...[
                              const SizedBox(height: 10),
                              Text(
                                'PIN incorrecto · $attempts/${AppConstants.panicPinMaxAttempts} intentos',
                                style: const TextStyle(
                                  color: AppColors.severityCritical,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // Estado bloqueado
                      const Icon(Icons.lock_outline,
                          color: AppColors.accent, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Alarma bloqueada · Llama al 105',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  // 5 barras con alturas relativas fijas — la amplitud las escala todas
  static const _barRatios = [0.5, 0.75, 1.0, 0.75, 0.5];

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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // Abrir teclado automáticamente al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
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
    if (widget.controller.text.length == 4) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TextField real visible pero estilizado como parte del diseño
        TextField(
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
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
        // Dots visuales encima — tocar abre el teclado
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
                      : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isFilled
                        ? AppColors.severityCritical
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
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
    final color = hasContact ? AppColors.severityLow : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasContact ? Icons.location_on : Icons.location_off_outlined,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            hasContact
                ? 'GPS compartido con $contactName'
                : 'Sin contacto de confianza configurado',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.severityCritical),
      ),
    );
  }
}

// ─── PIN Setup Sheet (activación) ─────────────────────────────────────────────

class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet({required this.onConfirm});
  final void Function(String pin) onConfirm;

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
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

  void _onPinChanged() {
    if (mounted) setState(() {});
    if (_controller.text.length == 4) {
      widget.onConfirm(_controller.text);
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
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vas a necesitar este PIN de 4 dígitos para detener la alarma.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
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
              color: Colors.white,
              fontSize: 36,
              letterSpacing: 20,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: '••••',
              hintStyle: const TextStyle(
                  color: Colors.white24, fontSize: 36, letterSpacing: 20),
            ),
          ),
        ],
      ),
    );
  }
}
