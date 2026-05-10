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
    if (severity == Severity.high) {
      return _CriticalMarker(isSelected: isSelected, onTap: onTap);
    }

    final color = severity == Severity.low
        ? AppColors.severityLow
        : AppColors.severityModerate;
    final size = severity == Severity.low ? 24.0 : 28.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(Icons.bolt, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

class _CriticalMarker extends StatefulWidget {
  const _CriticalMarker({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CriticalMarker> createState() => _CriticalMarkerState();
}

class _CriticalMarkerState extends State<_CriticalMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.45, end: 0.0).animate(
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
          width: 56,
          height: 56,
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
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.severityCritical,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              // Pin central
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.severityCritical,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
