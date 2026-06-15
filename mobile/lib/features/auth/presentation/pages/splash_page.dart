import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;
  late final Animation<double> _bottomFade;
  late final Animation<double> _progressValue;
  late final Animation<double> _exitOpacity;

  AuthState? _pendingState;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _logoFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _bottomFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    _progressValue = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeOut,
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _entryCtrl.forward();
    _progressCtrl.forward();

    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && _pendingState != null) {
        _triggerExit(_pendingState!);
      }
    });

    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  Future<void> _triggerExit(AuthState state) async {
    if (_navigating || !mounted) return;
    _navigating = true;
    await _exitCtrl.forward();
    if (!mounted) return;
    _navigate(state);
  }

  void _navigate(AuthState state) {
    if (state is AuthAuthenticated) {
      context.go('/map');
    } else if (state is AuthUnauthenticated) {
      context.go(state.isFirstLaunch ? '/onboarding' : '/login');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthAuthenticated &&
            state is! AuthUnauthenticated &&
            state is! AuthError) {
          return;
        }

        if (_progressCtrl.isCompleted && !_navigating) {
          _triggerExit(state);
        } else {
          _pendingState = state;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SizedBox.expand(
          child: FadeTransition(
            opacity: _exitOpacity,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  'assets/images/logo/alertaya_logo_horizontal_white.svg',
                                  width: 220,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FadeTransition(
                              opacity: _taglineFade,
                              child: Text(
                                'Tu barrio, en tiempo real.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: FadeTransition(
                        opacity: _bottomFade,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 2,
                              child: AnimatedBuilder(
                                animation: _progressValue,
                                builder: (context, _) => LinearProgressIndicator(
                                  value: _progressValue.value,
                                  backgroundColor: AppColors.outline
                                      .withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'LIMA, PERÚ',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.outline,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
