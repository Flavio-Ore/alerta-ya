import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';

enum _SlideKind { realtime, report, anonymous }

class _Slide {
  const _Slide({
    required this.kind,
    required this.headline,
    required this.body,
  });
  final _SlideKind kind;
  final String headline;
  final String body;
}

const _slides = [
  _Slide(
    kind: _SlideKind.realtime,
    headline: 'Alertas en tiempo real',
    body:
        'Entérate al instante de lo que pasa en tu zona. El mapa se actualiza solo.',
  ),
  _Slide(
    kind: _SlideKind.report,
    headline: 'Reporta en menos de 10 segundos',
    body:
        'Elige el tipo de incidente, responde 3 preguntas rápidas y el sistema hace el resto.',
  ),
  _Slide(
    kind: _SlideKind.anonymous,
    headline: 'Tu identidad, siempre protegida',
    body: 'Eres anónimo para todos. Solo tú sabes que reportaste.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _showingPermission = false;

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _showingPermission = true);
    }
  }

  Future<void> _activateAndFinish() async {
    if (!kIsWeb && Platform.isAndroid) {
      await Permission.notification.request();
    }
    _completeOnboarding();
  }

  void _completeOnboarding() {
    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthOnboardingCompleted());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingPermission) {
      return _NotificationPermissionStep(
        onActivate: _activateAndFinish,
        onSkip: _completeOnboarding,
      );
    }

    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            // ── Ilustración (45% — paginable)
            Expanded(
              flex: 45,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) =>
                    _SlideIllustration(kind: _slides[i].kind),
              ),
            ),
            // ── Card inferior (55% — textos animados)
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    _ProgressDots(
                      currentPage: _currentPage,
                      total: _slides.length,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(slide.kind),
                          children: [
                            Text(
                              slide.headline,
                              style: AppTextStyles.headlineLg,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide.body,
                              style: AppTextStyles.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AlertaYaButton(
                      label: isLast ? 'Empezar' : 'Siguiente',
                      onPressed: _next,
                    ),
                    const SizedBox(height: 8),
                    // Reserva el espacio aún cuando se oculta para evitar saltos
                    SizedBox(
                      height: 48,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isLast ? 0 : 1,
                        child: TextButton(
                          onPressed: isLast ? null : _completeOnboarding,
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            'Omitir',
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Indicador de progreso
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.currentPage, required this.total});
  final int currentPage;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == currentPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                i == currentPage ? AppColors.primary : AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ilustraciones por slide — composiciones con íconos + tokens de marca.
// Sin assets externos. Cada slide tiene una imagen visual distinta.
// ─────────────────────────────────────────────────────────────────────────────

class _SlideIllustration extends StatelessWidget {
  const _SlideIllustration({required this.kind});
  final _SlideKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: switch (kind) {
          _SlideKind.realtime => const _RealtimeIllustration(),
          _SlideKind.report => const _ReportIllustration(),
          _SlideKind.anonymous => const _AnonymousIllustration(),
        },
      ),
    );
  }
}

class _RealtimeIllustration extends StatelessWidget {
  const _RealtimeIllustration();

  @override
  Widget build(BuildContext context) {
    // Pin grande sobre fondo radial — comunica "mapa + ubicación + alerta".
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ondas concéntricas
        ...List.generate(
          3,
          (i) => Container(
            width: 80.0 + i * 60,
            height: 80.0 + i * 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3 - i * 0.08),
                width: 1.5,
              ),
            ),
          ),
        ),
        // Pin central
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on,
            color: AppColors.secondary,
            size: 48,
          ),
        ),
      ],
    );
  }
}

class _ReportIllustration extends StatelessWidget {
  const _ReportIllustration();

  @override
  Widget build(BuildContext context) {
    // Tarjeta de reporte estilizada — comunica "formulario rápido".
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 100,
                            height: 8,
                            decoration: BoxDecoration(
                                color: AppColors.outline,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 6),
                        Container(
                            width: 60,
                            height: 6,
                            decoration: BoxDecoration(
                                color: AppColors.outlineVariant,
                                borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _LineBar(),
                const SizedBox(height: 8),
                const _LineBar(widthFactor: 0.7),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineBar extends StatelessWidget {
  const _LineBar({this.widthFactor = 1.0});
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso final: solicitar permiso de notificaciones con contexto
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationPermissionStep extends StatelessWidget {
  const _NotificationPermissionStep({
    required this.onActivate,
    required this.onSkip,
  });

  final VoidCallback onActivate;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 45,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(
                        3,
                        (i) => Container(
                          width: 80.0 + i * 56,
                          height: 80.0 + i * 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.35 - i * 0.1),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.secondary,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Activa las alertas',
                            style: AppTextStyles.headlineLg,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Te avisamos al instante cuando algo pasa en tu zona. Puedes desactivarlas cuando quieras.',
                            style: AppTextStyles.bodyMd,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    AlertaYaButton(
                      label: 'Activar alertas',
                      onPressed: onActivate,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          'Ahora no',
                          style: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
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

class _AnonymousIllustration extends StatelessWidget {
  const _AnonymousIllustration();

  @override
  Widget build(BuildContext context) {
    // Escudo con check — comunica "identidad protegida".
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 130,
          height: 130,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.secondary,
            size: 72,
          ),
        ),
        const Positioned(
          bottom: 50,
          right: 50,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary,
            child: Icon(Icons.lock_rounded,
                color: AppColors.primary, size: 18),
          ),
        ),
      ],
    );
  }
}
