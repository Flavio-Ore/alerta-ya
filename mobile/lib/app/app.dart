import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/app/router/app_router.dart';
import 'package:alertaya/app/router/go_router_refresh_stream.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/core/realtime/socket_client.dart';
import 'package:alertaya/core/services/fcm_service.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:alertaya/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:alertaya/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:alertaya/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:alertaya/features/report/presentation/bloc/report_bloc.dart';

class AlertaYaApp extends StatefulWidget {
  const AlertaYaApp({super.key});

  @override
  State<AlertaYaApp> createState() => _AlertaYaAppState();
}

class _AlertaYaAppState extends State<AlertaYaApp> {
  late final AuthBloc _authBloc;
  late final PanicBloc _panicBloc;
  late final ProfileBloc _profileBloc;
  late final FcmService _fcm;
  late final GoRouterRefreshStream _refreshStream;
  late final GoRouter _router;

  // Key global del ScaffoldMessenger para mostrar snackbars desde cualquier lado
  // (eg. notif FCM en foreground) sin necesidad de context.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<FcmIncidentNotification>? _fcmForegroundSub;
  StreamSubscription<FcmIncidentNotification>? _fcmOpenedSub;
  StreamSubscription<FcmConfirmRequestNotification>? _fcmConfirmRequestSub;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _panicBloc = getIt<PanicBloc>()..add(const PanicInitialized());
    _profileBloc = getIt<ProfileBloc>()..add(const ProfileLoaded());
    _fcm = getIt<FcmService>();
    _refreshStream = GoRouterRefreshStream(_authBloc.stream);
    _router = createRouter(_authBloc, _refreshStream);

    // Notif FCM en foreground → snackbar con tap para ir al detalle.
    _fcmForegroundSub = _fcm.onForegroundMessage.listen((ev) {
      final messenger = _messengerKey.currentState;
      if (messenger == null) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ev.title,
                style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                ev.body,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VER',
            textColor: AppColors.secondary,
            onPressed: () => _router.push('/map/incident/${ev.incidentId}'),
          ),
        ),
      );
    });

    // Tap en notif desde background/cold start → navegar directo al detalle.
    _fcmOpenedSub = _fcm.onNotificationOpened.listen((ev) {
      _router.push('/map/incident/${ev.incidentId}');
    });

    // Confirm-request por FCM (background o foreground) → navegar al mapa e
    // inyectar el evento al IncidentsBloc. El listener del MapPage abre el sheet.
    _fcmConfirmRequestSub = _fcm.onConfirmRequest.listen((ev) {
      try {
        final crEvent = ConfirmRequestEvent(
          zoneLabel: ev.zoneLabel,
          type: IncidentType.fromValue(ev.incidentType),
          approxLat: ev.approxLat,
          approxLng: ev.approxLng,
          reportedAt: ev.reportedAt,
        );
        // Si no estamos en el mapa, navegar — el bloc ya recibe el evento global.
        _router.go('/map');
        getIt<IncidentsBloc>().add(ConfirmRequestReceived(crEvent));
      } catch (e) {
        // IncidentType.fromValue puede lanzar si el tipo es desconocido.
        // Fallback: solo navegar al mapa, sin sheet.
        _router.go('/map');
      }
    });
  }

  @override
  void dispose() {
    _fcmForegroundSub?.cancel();
    _fcmOpenedSub?.cancel();
    _fcmConfirmRequestSub?.cancel();
    _router.dispose();
    _refreshStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _buildUrbanSentinelTheme();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _panicBloc),
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: getIt<ReportBloc>()),
        BlocProvider.value(value: getIt<IncidentsBloc>()),
      ],
      child: MaterialApp.router(
        title: 'AlertaYa',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messengerKey,
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}

ThemeData _buildUrbanSentinelTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      surfaceBright: AppColors.surfaceBright,
      surfaceDim: AppColors.surfaceDim,
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      onPrimary: AppColors.onPrimary,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondary: AppColors.onSecondary,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiary: AppColors.onTertiary,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
      onError: AppColors.onError,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    canvasColor: AppColors.surface,
    fontFamily: 'DMSans',
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLg,
      headlineLarge: AppTextStyles.headlineLg,
      headlineMedium: AppTextStyles.headlineMd,
      headlineSmall: AppTextStyles.headlineSm,
      titleLarge: AppTextStyles.titleLg,
      titleMedium: AppTextStyles.titleMd,
      titleSmall: AppTextStyles.titleSm,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.bodyMd,
      bodySmall: AppTextStyles.bodySm,
      labelLarge: AppTextStyles.labelLg,
      labelMedium: AppTextStyles.labelMd,
      labelSmall: AppTextStyles.labelSm,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerHigh,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppTextStyles.labelLg,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppTextStyles.labelLg,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelLg,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleLg,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: AppColors.outline,
        fontFamily: 'DMSans',
      ),
      labelStyle: const TextStyle(
        color: AppColors.onSurfaceVariant,
        fontFamily: 'DMSans',
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      space: 0,
      thickness: 0,
    ),
    iconTheme: const IconThemeData(color: AppColors.onSurface),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
