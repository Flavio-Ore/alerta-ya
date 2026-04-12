import 'package:flutter/material.dart';

import 'package:alertaya/app/router/app_router.dart';
import 'package:alertaya/core/constants/app_colors.dart';

class AlertaYaApp extends StatelessWidget {
  const AlertaYaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AlertaYa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'DMSans',
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgLight,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
