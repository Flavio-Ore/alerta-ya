import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

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
      if (mounted) setState(() => _elapsed = DateTime.now().difference(startedAt));
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
      }
    } catch (_) {
      // Lima centro como fallback si falla el GPS
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
    return BlocConsumer<PanicBloc, PanicState>(
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
            canDeactivate: _pinController.text.length == 4,
            onDeactivate: _submitDeactivation,
          );
        }
        return _IdleView(onPanicTap: _showPinSetupSheet);
      },
    );
  }
}

// ─── S09: Idle ────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPanicTap});
  final VoidCallback onPanicTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Center(
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
                      Icon(Icons.warning_rounded, color: Colors.white, size: 56),
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
    required this.canDeactivate,
    required this.onDeactivate,
  });
  final PanicActive state;
  final Duration elapsed;
  final TextEditingController pinController;
  final bool canDeactivate;
  final VoidCallback onDeactivate;

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  List<Widget> _headerChildren() => [
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.severityCritical.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.severityCritical, width: 1),
          ),
          child: const Text(
            'ALARMA ACTIVA',
            style: TextStyle(
              color: AppColors.severityCritical,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          _format(elapsed),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w200,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tiempo transcurrido',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final locked = state.isPinLocked;
    final attempts = state.failedPinAttempts;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: locked ? _buildLockedBody() : _buildUnlockedBody(attempts),
        ),
      ),
    );
  }

  Widget _buildLockedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ..._headerChildren(),
        const Spacer(),
        const Icon(Icons.lock_outline, color: AppColors.accent, size: 36),
        const SizedBox(height: 12),
        const Text(
          'Alarma bloqueada',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Demasiados intentos fallidos.\nLlamá a emergencias: 105',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildUnlockedBody(int attempts) {
    return SingleChildScrollView(
      reverse: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ..._headerChildren(),
          const SizedBox(height: 48),
          const Text(
            'Ingresá tu PIN para desactivar',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
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
          if (attempts > 0) ...[
            const SizedBox(height: 12),
            Text(
              'PIN incorrecto — $attempts/${AppConstants.panicPinMaxAttempts} intentos',
              style: const TextStyle(
                  color: AppColors.severityCritical, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canDeactivate ? onDeactivate : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.severityCritical,
                disabledBackgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Desactivar alarma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 52),
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

  bool get _ready => _controller.text.length == 4;

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
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _ready ? () => widget.onConfirm(_controller.text) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.severityCritical,
                disabledBackgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Activar alarma',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
