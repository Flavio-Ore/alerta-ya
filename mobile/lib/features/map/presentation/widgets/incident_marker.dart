import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/domain/enums.dart';

class IncidentMarker extends StatelessWidget {
  const IncidentMarker({
    super.key,
    required this.severity,
    required this.isSelected,
    required this.onTap,
  });

  final Severity severity;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    switch (severity) {
      // Crítico: pulso fuerte y rápido — máxima atención.
      case Severity.critical:
        return _PulsingMarker(
          color: AppColors.severityCritical,
          coreSize: 32,
          boxSize: 56,
          ringScaleEnd: 1.5,
          ringOpacityBegin: 0.45,
          duration: const Duration(milliseconds: 1400),
          iconSize: 16,
          isSelected: isSelected,
          onTap: onTap,
        );
      // Moderado: pulso SUTIL — da dinamismo sin competir con el crítico.
      case Severity.moderate:
        return _PulsingMarker(
          color: AppColors.severityModerate,
          coreSize: 28,
          boxSize: 50,
          ringScaleEnd: 1.3,
          ringOpacityBegin: 0.28,
          duration: const Duration(milliseconds: 2200),
          iconSize: 14,
          isSelected: isSelected,
          onTap: onTap,
        );
      // Bajo: estático — mantiene la jerarquía visual.
      case Severity.low:
        return GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.severityLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 12),
            ),
          ),
        );
    }
  }
}

/// Marcador con anillo pulsante reutilizable. La intensidad del pulso (escala,
/// opacidad, velocidad) se parametriza para preservar la jerarquía por gravedad.
class _PulsingMarker extends StatefulWidget {
  const _PulsingMarker({
    required this.color,
    required this.coreSize,
    required this.boxSize,
    required this.ringScaleEnd,
    required this.ringOpacityBegin,
    required this.duration,
    required this.iconSize,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final double coreSize;
  final double boxSize;
  final double ringScaleEnd;
  final double ringOpacityBegin;
  final Duration duration;
  final double iconSize;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _scale = Tween<double>(begin: 1.0, end: widget.ringScaleEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: widget.ringOpacityBegin, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: widget.boxSize,
          height: widget.boxSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anillo pulsante exterior
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Transform.scale(
                  scale: _scale.value,
                  child: Opacity(
                    opacity: _opacity.value,
                    child: Container(
                      width: widget.coreSize,
                      height: widget.coreSize,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              // Pin central
              Container(
                width: widget.coreSize,
                height: widget.coreSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt, color: Colors.white, size: widget.iconSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
