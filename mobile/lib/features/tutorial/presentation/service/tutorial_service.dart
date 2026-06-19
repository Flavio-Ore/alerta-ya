import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/features/tutorial/domain/usecases/is_tutorial_seen_usecase.dart';
import 'package:alertaya/features/tutorial/domain/usecases/mark_tutorial_seen_usecase.dart';
import 'package:alertaya/features/tutorial/domain/usecases/reset_tutorial_usecase.dart';
import 'package:alertaya/features/tutorial/presentation/builder/tutorial_targets_builder.dart';
import 'package:alertaya/features/tutorial/presentation/keys/tutorial_keys.dart';

/// Orquesta el ciclo de vida del tutorial guiado.
///
/// - [maybeStart]: muestra el tutorial si el usuario nunca lo vio (leído de Hive).
///   Incluye un delay de 800ms para garantizar que los widgets objetivo —
///   ubicados en MapPage y AlertaYaBottomNav— ya están montados y tienen
///   sus GlobalKeys resueltas.
///
/// - [startManually]: fuerza la aparición del tutorial ignorando el flag.
///   Usado desde Perfil para que el usuario lo vea de nuevo.
@lazySingleton
class TutorialService {
  TutorialService(
    this._isSeen,
    this._markSeen,
    this._reset,
    this._keys,
  );

  final IsTutorialSeenUseCase _isSeen;
  final MarkTutorialSeenUseCase _markSeen;
  final ResetTutorialUseCase _reset;
  final TutorialKeys _keys;

  // Evita disparos concurrentes si se llama maybeStart varias veces seguidas.
  bool _isActive = false;

  /// Muestra el tutorial si el usuario nunca lo vio.
  ///
  /// Llamar desde AppShell tras el primer frame en la rama del mapa (branch 0).
  Future<void> maybeStart(BuildContext context) async {
    if (_isActive) return;

    final result = await _isSeen();
    final seen = result.fold((_) => true, (v) => v);
    if (seen) return;

    _isActive = true;

    // Esperamos que MapPage termine de construir y sus GlobalKeys estén montadas.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!context.mounted) {
      _isActive = false;
      return;
    }

    _show(context);
  }

  /// Relanza el tutorial desde cero, sin importar el flag persistido.
  ///
  /// Llamar desde Perfil después de navegar al mapa.
  /// No necesita esperar: AppShell.didUpdateWidget detecta el cambio de branch
  /// y delega a [maybeStart], que ya incluye el delay.
  Future<void> prepareManualRestart() async {
    _isActive = false;
    await _reset();
  }

  void _show(BuildContext context) {
    final targets = buildTutorialTargets(_keys);

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.surface,
      opacityShadow: 0.92,
      textSkip: 'Omitir',
      alignSkip: Alignment.topRight,
      paddingFocus: 8,
      focusAnimationDuration: const Duration(milliseconds: 400),
      onFinish: _complete,
      onSkip: () {
        _complete();
        return true;
      },
    ).show(context: context);
  }

  void _complete() {
    _isActive = false;
    // Fire-and-forget: el tutorial ya se mostró, persistimos el flag.
    _markSeen();
  }
}
