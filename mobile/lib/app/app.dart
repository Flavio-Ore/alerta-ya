import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/app/router/app_router.dart';
import 'package:alertaya/app/router/go_router_refresh_stream.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';

class AlertaYaApp extends StatefulWidget {
  const AlertaYaApp({super.key});

  @override
  State<AlertaYaApp> createState() => _AlertaYaAppState();
}

class _AlertaYaAppState extends State<AlertaYaApp> {
  late final AuthBloc _authBloc;
  late final GoRouterRefreshStream _refreshStream;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _refreshStream = GoRouterRefreshStream(_authBloc.stream);
    _router = createRouter(_authBloc, _refreshStream);
  }

  @override
  void dispose() {
    _router.dispose();
    _refreshStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
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
        routerConfig: _router,
      ),
    );
  }
}
