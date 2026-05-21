import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import '../bloc/auth_bloc.dart';

class _Slide {
  const _Slide({required this.headline, required this.body, required this.icon});
  final String headline;
  final String body;
  final IconData icon;
}

const _slides = [
  _Slide(
    headline: 'Alertas en tiempo real',
    body: 'Enterate al instante de lo que pasa en tu zona. El mapa se actualiza solo.',
    icon: Icons.notifications_active_outlined,
  ),
  _Slide(
    headline: 'Reportá en menos de 10 segundos',
    body: 'Elegí el tipo de incidente, respondé 3 preguntas rápidas y el sistema hace el resto.',
    icon: Icons.edit_location_alt_outlined,
  ),
  _Slide(
    headline: 'Tu identidad, siempre protegida',
    body: 'Sos anónimo para todos. Solo vos sabés que reportaste.',
    icon: Icons.shield_outlined,
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

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    context.read<AuthBloc>().add(const AuthOnboardingCompleted());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Ilustración (45% de la pantalla)
            Expanded(
              flex: 45,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideIllustration(slide: _slides[i]),
              ),
            ),
            // Tarjeta inferior (55%)
            Expanded(
              flex: 55,
              child: _BottomCard(
                slide: _slides[_currentPage],
                currentPage: _currentPage,
                total: _slides.length,
                isLast: _currentPage == _slides.length - 1,
                onNext: _next,
                onSkip: _finish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideIllustration extends StatelessWidget {
  const _SlideIllustration({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/images/logo/alertaya_isotipo.svg', width: 64),
          const SizedBox(height: 24),
          Icon(slide.icon, size: 48, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard({
    required this.slide,
    required this.currentPage,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final _Slide slide;
  final int currentPage;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Puntos de progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              total,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == currentPage ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == currentPage ? AppColors.primary : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(slide.headline, style: AppTextStyles.h1, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          AlertaYaButton(
            label: isLast ? 'Empezar' : 'Siguiente',
            onPressed: onNext,
          ),
          const SizedBox(height: 16),
          if (!isLast)
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Omitir',
                style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
