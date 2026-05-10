import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';

class ReportConfirmationPage extends StatefulWidget {
  const ReportConfirmationPage({super.key});

  @override
  State<ReportConfirmationPage> createState() => _ReportConfirmationPageState();
}

class _ReportConfirmationPageState extends State<ReportConfirmationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late final Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _spinAnimation = Tween<double>(begin: 0, end: -1).animate(_spinController);
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: Row(
          children: [
            Text('Alerta', style: AppTextStyles.logoAlerta.copyWith(fontSize: 18)),
            Text('Ya', style: AppTextStyles.logoYa.copyWith(fontSize: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Hero — checkmark
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.severityLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Reporte Enviado', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'La IA está verificando coherencia...',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(width: 6),
                  RotationTransition(
                    turns: _spinAnimation,
                    child: const Icon(Icons.sync, color: AppColors.primary, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Chip anónimo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Tu identidad permanece anónima',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Timeline de estado
              _StatusTimeline(spinAnimation: _spinAnimation),
              const SizedBox(height: 24),
              // Nota de threshold
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Se necesitan 2 reportes independientes en 15 min para publicar en el mapa. Recibirás una notificación si se confirma.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AlertaYaButton(
                label: 'Volver al Mapa',
                onPressed: () => context.go('/map'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver estado del reporte',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.spinAnimation});
  final Animation<double> spinAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          icon: Icons.check,
          iconColor: Colors.white,
          circleBg: AppColors.severityLow,
          title: 'Reporte recibido',
          subtitle: 'Hace un momento',
          showLine: true,
          lineColor: AppColors.severityLow.withValues(alpha: 0.3),
          isDone: true,
        ),
        _TimelineItem(
          customIcon: RotationTransition(
            turns: spinAnimation,
            child: const Icon(Icons.sync, color: AppColors.accent, size: 14),
          ),
          circleBg: AppColors.bgGray,
          circleBorder: AppColors.accent,
          title: 'Verificando con IA',
          subtitle: 'En proceso...',
          titleColor: AppColors.accent,
          showLine: true,
          lineColor: AppColors.textMuted.withValues(alpha: 0.3),
          isDone: false,
        ),
        const _TimelineItem(
          circleBg: AppColors.bgGray,
          circleBorder: AppColors.textMuted,
          title: 'Publicando en el mapa',
          subtitle: 'Esperando threshold',
          titleColor: AppColors.textMuted,
          subtitleColor: AppColors.textMuted,
          showLine: false,
          isDone: false,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    this.icon,
    this.customIcon,
    this.iconColor,
    required this.circleBg,
    this.circleBorder,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.subtitleColor,
    required this.showLine,
    this.lineColor,
    required this.isDone,
  });

  final IconData? icon;
  final Widget? customIcon;
  final Color? iconColor;
  final Color circleBg;
  final Color? circleBorder;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final bool showLine;
  final Color? lineColor;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    border: circleBorder != null
                        ? Border.all(color: circleBorder!, width: 1.5)
                        : null,
                  ),
                  child: customIcon ??
                      (icon != null
                          ? Icon(icon, color: iconColor, size: 14)
                          : null),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: lineColor ?? AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: subtitleColor ?? AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
