import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import 'package:alertaya/features/report/presentation/bloc/report_bloc.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.go('/map'),
        ),
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/logo/alertaya_logo_horizontal_white.svg',
              height: 28,
            )
          ],
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportFailure) {
              return _FailureBody(message: state.message);
            }
            if (state is ReportSubmitting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }
            final bool isPublished =
                state is ReportSuccess ? state.isPublished : false;
            final int? reputationDelta =
                state is ReportSuccess ? state.reputationDelta : null;
            return _SuccessBody(
              spinAnimation: _spinAnimation,
              isPublished: isPublished,
              reputationDelta: reputationDelta,
            );
          },
        ),
      ),
    );
  }
}

class _SuccessBody extends StatefulWidget {
  const _SuccessBody({
    required this.spinAnimation,
    required this.isPublished,
    this.reputationDelta,
  });

  final Animation<double> spinAnimation;
  final bool isPublished;
  final int? reputationDelta;

  @override
  State<_SuccessBody> createState() => _SuccessBodyState();
}

class _SuccessBodyState extends State<_SuccessBody> {
  bool _showDelta = false;

  @override
  void initState() {
    super.initState();
    if (widget.reputationDelta != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showDelta = true);
      });
    }
  }

  String get _title =>
      widget.isPublished ? 'Reporte Publicado' : 'Reporte Enviado';

  String get _statusLine => widget.isPublished
      ? 'Ya aparece en el mapa de los ciudadanos cercanos.'
      : 'Aparecerá en el mapa cuando otro ciudadano lo confirme.';

  String get _detailMessage => widget.isPublished
      ? 'Tu reporte se publicó. Ya aparece en el mapa de los ciudadanos cercanos.'
      : 'Tu reporte fue recibido. Aparecerá públicamente cuando otro ciudadano cercano confirme un incidente del mismo tipo.';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text(_title, style: AppTextStyles.headlineLg),
          const SizedBox(height: 8),
          Text(
            _statusLine,
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
          ),
          // B5.3 — Reputation delta chip: fade-in after 600ms delay.
          // Only shown when ML returned a delta (non-null).
          if (widget.reputationDelta != null) ...[
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: _showDelta ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: _ReputationDeltaChip(delta: widget.reputationDelta!),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Tu identidad permanece anónima',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _StatusTimeline(
            spinAnimation: widget.spinAnimation,
            isPublished: widget.isPublished,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _detailMessage,
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.onSurfaceVariant),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// B5.2 — Delta chip shown below the main success message.
// Green for positive delta, orange/amber for negative, neutral for zero.
class _ReputationDeltaChip extends StatelessWidget {
  const _ReputationDeltaChip({required this.delta});
  final int delta;

  Color get _color {
    if (delta > 0) return AppColors.success;
    if (delta < 0) return AppColors.severityModerate;
    return AppColors.onSurfaceVariant;
  }

  String get _label {
    if (delta > 0) return '+$delta puntos de reputación';
    if (delta < 0) return '$delta puntos de reputación';
    return 'Sin cambio de reputación';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            delta >= 0 ? Icons.star_rounded : Icons.star_half_rounded,
            size: 15,
            color: _color,
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: AppTextStyles.labelMd.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.severityCritical,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('No se pudo enviar', style: AppTextStyles.headlineLg),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AlertaYaButton(
            label: 'Reintentar',
            onPressed: () {
              // Volver al formulario para que el usuario pueda reintentar.
              context.pop();
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/map'),
            child: Text(
              'Volver al mapa',
              style: AppTextStyles.bodyLg.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({
    required this.spinAnimation,
    required this.isPublished,
  });
  final Animation<double> spinAnimation;
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          icon: Icons.check,
          iconColor: Colors.white,
          circleBg: AppColors.success,
          title: 'Reporte recibido',
          subtitle: 'Hace un momento',
          showLine: true,
          lineColor: AppColors.success.withValues(alpha: 0.3),
          isDone: true,
        ),
        _TimelineItem(
          customIcon: isPublished
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : RotationTransition(
                  turns: spinAnimation,
                  child: const Icon(Icons.sync,
                      color: AppColors.secondary, size: 14),
                ),
          circleBg: isPublished ? AppColors.success : AppColors.surfaceContainerLow,
          circleBorder: isPublished ? null : AppColors.secondary,
          title: isPublished ? 'Verificado' : 'Esperando confirmación',
          subtitle: isPublished
              ? 'Confirmado por ciudadanos cercanos'
              : 'Pendiente de otro reporte',
          titleColor: isPublished ? null : AppColors.secondary,
          showLine: true,
          lineColor: (isPublished ? AppColors.success : AppColors.outline)
              .withValues(alpha: 0.3),
          isDone: isPublished,
        ),
        _TimelineItem(
          icon: isPublished ? Icons.check : null,
          iconColor: isPublished ? Colors.white : null,
          circleBg: isPublished ? AppColors.success : AppColors.surfaceContainerLow,
          circleBorder: isPublished ? null : AppColors.outline,
          title:
              isPublished ? 'Publicado en el mapa' : 'Publicando en el mapa',
          subtitle: isPublished ? 'Visible para todos' : 'Esperando confirmación',
          titleColor: isPublished ? null : AppColors.outline,
          subtitleColor: isPublished ? null : AppColors.outline,
          showLine: false,
          isDone: isPublished,
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
                      color: lineColor ?? AppColors.outline,
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
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: titleColor ?? AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelMd.copyWith(
                      color: subtitleColor ?? AppColors.onSurfaceVariant,
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
