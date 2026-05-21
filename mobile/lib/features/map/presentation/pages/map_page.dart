import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Mapa', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Tú mismo eres Anthony, lucete con el mapa',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/report/type'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgLight,
        elevation: 0,
        icon: const Icon(Icons.add_alert_outlined),
        label: Text(
          'Reportar',
          style: AppTextStyles.buttonLabel.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}
