import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/widgets/severity_chip.dart';

/// Pin del mapa por severidad.
/// LEVE: 24px verde, MODERADO: 28px ámbar, CRÍTICO: 32px rojo + anillo pulsante
class SeverityPin extends StatefulWidget {
  const SeverityPin({
    super.key,
    required this.severity,
    this.isSelected = false,
  });

  final SeverityLevel severity;
  final bool isSelected;

  @override
  State<SeverityPin> createState() => _SeverityPinState();
}

class _SeverityPinState extends State<SeverityPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    if (widget.severity == SeverityLevel.critical) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _pinConfig(widget.severity);
    final scale = widget.isSelected ? 1.2 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 150),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.severity == SeverityLevel.critical)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: config.size,
                  height: config.size,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          Container(
            width: config.size,
            height: config.size,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  _PinConfig _pinConfig(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return const _PinConfig(color: AppColors.severityLow, size: 24);
      case SeverityLevel.moderate:
        return const _PinConfig(color: AppColors.severityModerate, size: 28);
      case SeverityLevel.critical:
        return const _PinConfig(color: AppColors.severityCritical, size: 32);
    }
  }
}

class _PinConfig {
  const _PinConfig({required this.color, required this.size});
  final Color color;
  final double size;
}
