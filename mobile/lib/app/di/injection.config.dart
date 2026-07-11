// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:alertaya/core/di/firebase_module.dart' as _i1044;
import 'package:alertaya/core/network/dio_module.dart' as _i197;
import 'package:alertaya/core/network/network_info.dart' as _i857;
import 'package:alertaya/core/realtime/socket_client.dart' as _i635;
import 'package:alertaya/core/services/fcm_service.dart' as _i66;
import 'package:alertaya/core/services/firebase_storage_service.dart' as _i457;
import 'package:alertaya/core/services/location_service.dart' as _i919;
import 'package:alertaya/core/services/media_upload_service.dart' as _i846;
import 'package:alertaya/core/storage/secure_storage_service.dart' as _i142;
import 'package:alertaya/features/alerts/data/datasources/notification_remote_datasource.dart'
    as _i238;
import 'package:alertaya/features/alerts/data/repositories/notification_repository_impl.dart'
    as _i303;
import 'package:alertaya/features/alerts/domain/repositories/notification_repository.dart'
    as _i328;
import 'package:alertaya/features/alerts/domain/usecases/get_notifications_usecase.dart'
    as _i750;
import 'package:alertaya/features/alerts/domain/usecases/mark_notifications_read_usecase.dart'
    as _i748;
import 'package:alertaya/features/alerts/presentation/bloc/alerts_bloc.dart'
    as _i767;
import 'package:alertaya/features/auth/data/datasources/firebase_auth_datasource.dart'
    as _i781;
import 'package:alertaya/features/auth/data/datasources/onboarding_local_datasource.dart'
    as _i852;
import 'package:alertaya/features/auth/data/repositories/auth_repository_impl.dart'
    as _i779;
import 'package:alertaya/features/auth/domain/repositories/auth_repository.dart'
    as _i576;
import 'package:alertaya/features/auth/domain/usecases/complete_onboarding_usecase.dart'
    as _i401;
import 'package:alertaya/features/auth/domain/usecases/delete_account_usecase.dart'
    as _i316;
import 'package:alertaya/features/auth/domain/usecases/is_first_launch_usecase.dart'
    as _i586;
import 'package:alertaya/features/auth/domain/usecases/sign_in_with_email_usecase.dart'
    as _i351;
import 'package:alertaya/features/auth/domain/usecases/sign_out_usecase.dart'
    as _i290;
import 'package:alertaya/features/auth/domain/usecases/sign_up_with_email_usecase.dart'
    as _i141;
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart'
    as _i70;
import 'package:alertaya/features/incidents/data/datasources/incident_remote_datasource.dart'
    as _i860;
import 'package:alertaya/features/incidents/data/repositories/incident_repository_impl.dart'
    as _i93;
import 'package:alertaya/features/incidents/domain/repositories/incident_repository.dart'
    as _i512;
import 'package:alertaya/features/incidents/domain/usecases/confirm_incident_usecase.dart'
    as _i715;
import 'package:alertaya/features/incidents/domain/usecases/confirm_zone_usecase.dart'
    as _i414;
import 'package:alertaya/features/incidents/domain/usecases/get_incident_detail_usecase.dart'
    as _i125;
import 'package:alertaya/features/incidents/domain/usecases/get_incidents_usecase.dart'
    as _i1069;
import 'package:alertaya/features/incidents/presentation/bloc/incidents_bloc.dart'
    as _i352;
import 'package:alertaya/features/my_reports/data/datasources/my_reports_remote_datasource.dart'
    as _i750;
import 'package:alertaya/features/my_reports/data/repositories/my_reports_repository_impl.dart'
    as _i97;
import 'package:alertaya/features/my_reports/domain/repositories/my_reports_repository.dart'
    as _i431;
import 'package:alertaya/features/my_reports/domain/usecases/cancel_report_usecase.dart'
    as _i339;
import 'package:alertaya/features/my_reports/domain/usecases/get_my_reports_usecase.dart'
    as _i56;
import 'package:alertaya/features/my_reports/domain/usecases/watch_my_reports_usecase.dart'
    as _i972;
import 'package:alertaya/features/my_reports/presentation/bloc/my_reports_bloc.dart'
    as _i250;
import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart'
    as _i132;
import 'package:alertaya/features/panic/data/datasources/panic_remote_datasource.dart'
    as _i973;
import 'package:alertaya/features/panic/data/repositories/panic_repository_impl.dart'
    as _i432;
import 'package:alertaya/features/panic/data/services/audio_recording_service.dart'
    as _i42;
import 'package:alertaya/features/panic/data/services/escrow_key_submitter.dart'
    as _i513;
import 'package:alertaya/features/panic/data/services/panic_channel_service.dart'
    as _i419;
import 'package:alertaya/features/panic/data/services/panic_location_tracker.dart'
    as _i655;
import 'package:alertaya/features/panic/data/services/panic_upload_service.dart'
    as _i705;
import 'package:alertaya/features/panic/data/services/sms_service.dart'
    as _i764;
import 'package:alertaya/features/panic/data/services/trusted_contact_service.dart'
    as _i732;
import 'package:alertaya/features/panic/domain/repositories/panic_repository.dart'
    as _i519;
import 'package:alertaya/features/panic/domain/usecases/activate_panic_usecase.dart'
    as _i947;
import 'package:alertaya/features/panic/domain/usecases/deactivate_panic_usecase.dart'
    as _i434;
import 'package:alertaya/features/panic/presentation/bloc/panic_bloc.dart'
    as _i776;
import 'package:alertaya/features/profile/data/datasources/me_remote_datasource.dart'
    as _i554;
import 'package:alertaya/features/profile/presentation/bloc/profile_bloc.dart'
    as _i901;
import 'package:alertaya/features/report/data/datasources/report_remote_datasource.dart'
    as _i35;
import 'package:alertaya/features/report/data/repositories/report_repository_impl.dart'
    as _i1054;
import 'package:alertaya/features/report/domain/repositories/report_repository.dart'
    as _i658;
import 'package:alertaya/features/report/domain/usecases/create_report_usecase.dart'
    as _i280;
import 'package:alertaya/features/report/domain/usecases/get_form_schema_usecase.dart'
    as _i638;
import 'package:alertaya/features/report/presentation/bloc/report_bloc.dart'
    as _i108;
import 'package:alertaya/features/risk/data/datasources/risk_remote_datasource.dart'
    as _i444;
import 'package:alertaya/features/risk/data/repositories/risk_repository_impl.dart'
    as _i756;
import 'package:alertaya/features/risk/domain/repositories/risk_repository.dart'
    as _i312;
import 'package:alertaya/features/risk/presentation/bloc/risk_bloc.dart'
    as _i456;
import 'package:alertaya/features/tutorial/data/datasources/tutorial_local_datasource.dart'
    as _i614;
import 'package:alertaya/features/tutorial/data/repositories/tutorial_repository_impl.dart'
    as _i312;
import 'package:alertaya/features/tutorial/domain/repositories/tutorial_repository.dart'
    as _i463;
import 'package:alertaya/features/tutorial/domain/usecases/is_tutorial_seen_usecase.dart'
    as _i211;
import 'package:alertaya/features/tutorial/domain/usecases/mark_tutorial_seen_usecase.dart'
    as _i317;
import 'package:alertaya/features/tutorial/domain/usecases/reset_tutorial_usecase.dart'
    as _i187;
import 'package:alertaya/features/tutorial/presentation/keys/tutorial_keys.dart'
    as _i289;
import 'package:alertaya/features/tutorial/presentation/service/tutorial_service.dart'
    as _i847;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final firebaseModule = _$FirebaseModule();
    final dioModule = _$DioModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i457.FirebaseStorage>(
        () => firebaseModule.firebaseStorage);
    gh.lazySingleton<_i895.Connectivity>(() => dioModule.connectivity);
    gh.lazySingleton<_i361.Dio>(() => dioModule.dio());
    gh.lazySingleton<_i635.SocketClient>(
      () => _i635.SocketClient(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i919.LocationService>(() => _i919.LocationService());
    gh.lazySingleton<_i142.SecureStorageService>(
        () => const _i142.SecureStorageService());
    gh.lazySingleton<_i419.PanicChannelService>(
        () => _i419.PanicChannelService());
    gh.lazySingleton<_i655.PanicLocationTracker>(
        () => _i655.PanicLocationTracker());
    gh.lazySingleton<_i764.SmsService>(() => _i764.SmsService());
    gh.lazySingleton<_i289.TutorialKeys>(() => _i289.TutorialKeys());
    gh.lazySingleton<_i457.FirebaseStorageService>(
        () => _i457.FirebaseStorageService(gh<_i457.FirebaseStorage>()));
    gh.lazySingleton<_i238.NotificationRemoteDataSource>(
        () => _i238.NotificationRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i732.TrustedContactService>(
        () => _i732.TrustedContactService(gh<_i142.SecureStorageService>()));
    gh.lazySingleton<_i444.RiskRemoteDataSource>(
        () => _i444.RiskRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i554.MeRemoteDataSource>(
        () => _i554.MeRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i312.RiskRepository>(
        () => _i756.RiskRepositoryImpl(gh<_i444.RiskRemoteDataSource>()));
    gh.lazySingleton<_i973.PanicRemoteDataSource>(
        () => _i973.PanicRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i750.MyReportsRemoteDataSource>(
        () => _i750.MyReportsRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i852.OnboardingLocalDataSource>(
        () => _i852.OnboardingLocalDataSourceImpl());
    gh.lazySingleton<_i456.RiskBloc>(
        () => _i456.RiskBloc(gh<_i312.RiskRepository>()));
    gh.lazySingleton<_i66.FcmService>(() => _i66.FcmService(gh<_i361.Dio>()));
    gh.lazySingleton<_i860.IncidentRemoteDataSource>(
        () => _i860.IncidentRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i614.TutorialLocalDataSource>(
        () => _i614.TutorialLocalDataSourceImpl());
    gh.lazySingleton<_i35.ReportRemoteDataSource>(
        () => _i35.ReportRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i132.EscrowRemoteDataSource>(
        () => _i132.EscrowRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i857.NetworkInfo>(
        () => _i857.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i512.IncidentRepository>(
        () => _i93.IncidentRepositoryImpl(
              gh<_i860.IncidentRemoteDataSource>(),
              gh<_i857.NetworkInfo>(),
            ));
    gh.factory<_i901.ProfileBloc>(
        () => _i901.ProfileBloc(gh<_i554.MeRemoteDataSource>()));
    gh.lazySingleton<_i846.MediaUploadService>(
        () => _i846.MediaUploadService(gh<_i457.FirebaseStorageService>()));
    gh.lazySingleton<_i431.MyReportsRepository>(
        () => _i97.MyReportsRepositoryImpl(
              gh<_i750.MyReportsRemoteDataSource>(),
              gh<_i857.NetworkInfo>(),
              gh<_i635.SocketClient>(),
            ));
    gh.lazySingleton<_i781.FirebaseAuthDataSource>(
        () => _i781.FirebaseAuthDataSourceImpl(gh<_i59.FirebaseAuth>()));
    gh.lazySingleton<_i463.TutorialRepository>(() =>
        _i312.TutorialRepositoryImpl(gh<_i614.TutorialLocalDataSource>()));
    gh.lazySingleton<_i519.PanicRepository>(() => _i432.PanicRepositoryImpl(
          gh<_i973.PanicRemoteDataSource>(),
          gh<_i857.NetworkInfo>(),
        ));
    gh.factory<_i947.ActivatePanicUseCase>(
        () => _i947.ActivatePanicUseCase(gh<_i519.PanicRepository>()));
    gh.factory<_i434.DeactivatePanicUseCase>(
        () => _i434.DeactivatePanicUseCase(gh<_i519.PanicRepository>()));
    gh.lazySingleton<_i576.AuthRepository>(() => _i779.AuthRepositoryImpl(
          gh<_i781.FirebaseAuthDataSource>(),
          gh<_i852.OnboardingLocalDataSource>(),
          gh<_i361.Dio>(),
        ));
    gh.factory<_i715.ConfirmIncidentUseCase>(
        () => _i715.ConfirmIncidentUseCase(gh<_i512.IncidentRepository>()));
    gh.factory<_i414.ConfirmZoneUseCase>(
        () => _i414.ConfirmZoneUseCase(gh<_i512.IncidentRepository>()));
    gh.factory<_i1069.GetIncidentsUseCase>(
        () => _i1069.GetIncidentsUseCase(gh<_i512.IncidentRepository>()));
    gh.factory<_i125.GetIncidentDetailUseCase>(
        () => _i125.GetIncidentDetailUseCase(gh<_i512.IncidentRepository>()));
    gh.lazySingleton<_i352.IncidentsBloc>(() => _i352.IncidentsBloc(
          gh<_i1069.GetIncidentsUseCase>(),
          gh<_i125.GetIncidentDetailUseCase>(),
          gh<_i715.ConfirmIncidentUseCase>(),
          gh<_i414.ConfirmZoneUseCase>(),
          gh<_i635.SocketClient>(),
          gh<_i919.LocationService>(),
        ));
    gh.factory<_i513.EscrowKeySubmitter>(
        () => _i513.EscrowKeySubmitter(gh<_i132.EscrowRemoteDataSource>()));
    gh.lazySingleton<_i705.PanicUploadService>(() => _i705.PanicUploadService(
          gh<_i457.FirebaseStorageService>(),
          gh<_i132.EscrowRemoteDataSource>(),
        ));
    gh.factory<_i211.IsTutorialSeenUseCase>(
        () => _i211.IsTutorialSeenUseCase(gh<_i463.TutorialRepository>()));
    gh.factory<_i317.MarkTutorialSeenUseCase>(
        () => _i317.MarkTutorialSeenUseCase(gh<_i463.TutorialRepository>()));
    gh.factory<_i187.ResetTutorialUseCase>(
        () => _i187.ResetTutorialUseCase(gh<_i463.TutorialRepository>()));
    gh.lazySingleton<_i328.NotificationRepository>(
        () => _i303.NotificationRepositoryImpl(
              gh<_i238.NotificationRemoteDataSource>(),
              gh<_i857.NetworkInfo>(),
            ));
    gh.factory<_i401.CompleteOnboardingUseCase>(
        () => _i401.CompleteOnboardingUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i316.DeleteAccountUseCase>(
        () => _i316.DeleteAccountUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i586.IsFirstLaunchUseCase>(
        () => _i586.IsFirstLaunchUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i351.SignInWithEmailUseCase>(
        () => _i351.SignInWithEmailUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i290.SignOutUseCase>(
        () => _i290.SignOutUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i141.SignUpWithEmailUseCase>(
        () => _i141.SignUpWithEmailUseCase(gh<_i576.AuthRepository>()));
    gh.lazySingleton<_i658.ReportRepository>(() => _i1054.ReportRepositoryImpl(
          gh<_i35.ReportRemoteDataSource>(),
          gh<_i846.MediaUploadService>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i42.AudioRecordingService>(
        () => _i42.AudioRecordingService(
              gh<_i142.SecureStorageService>(),
              gh<_i513.EscrowKeySubmitter>(),
            ));
    gh.factory<_i339.CancelReportUseCase>(
        () => _i339.CancelReportUseCase(gh<_i431.MyReportsRepository>()));
    gh.factory<_i56.GetMyReportsUseCase>(
        () => _i56.GetMyReportsUseCase(gh<_i431.MyReportsRepository>()));
    gh.factory<_i972.WatchMyReportsUseCase>(
        () => _i972.WatchMyReportsUseCase(gh<_i431.MyReportsRepository>()));
    gh.factory<_i250.MyReportsBloc>(() => _i250.MyReportsBloc(
          gh<_i56.GetMyReportsUseCase>(),
          gh<_i972.WatchMyReportsUseCase>(),
          gh<_i339.CancelReportUseCase>(),
        ));
    gh.lazySingleton<_i847.TutorialService>(() => _i847.TutorialService(
          gh<_i211.IsTutorialSeenUseCase>(),
          gh<_i317.MarkTutorialSeenUseCase>(),
          gh<_i187.ResetTutorialUseCase>(),
          gh<_i289.TutorialKeys>(),
        ));
    gh.factory<_i70.AuthBloc>(() => _i70.AuthBloc(
          gh<_i351.SignInWithEmailUseCase>(),
          gh<_i141.SignUpWithEmailUseCase>(),
          gh<_i290.SignOutUseCase>(),
          gh<_i586.IsFirstLaunchUseCase>(),
          gh<_i401.CompleteOnboardingUseCase>(),
          gh<_i576.AuthRepository>(),
          gh<_i66.FcmService>(),
        ));
    gh.factory<_i750.GetNotificationsUseCase>(() =>
        _i750.GetNotificationsUseCase(gh<_i328.NotificationRepository>()));
    gh.factory<_i748.MarkNotificationsReadUseCase>(() =>
        _i748.MarkNotificationsReadUseCase(gh<_i328.NotificationRepository>()));
    gh.factory<_i280.CreateReportUseCase>(
        () => _i280.CreateReportUseCase(gh<_i658.ReportRepository>()));
    gh.factory<_i638.GetFormSchemaUseCase>(
        () => _i638.GetFormSchemaUseCase(gh<_i658.ReportRepository>()));
    gh.lazySingleton<_i776.PanicBloc>(() => _i776.PanicBloc(
          gh<_i947.ActivatePanicUseCase>(),
          gh<_i434.DeactivatePanicUseCase>(),
          gh<_i142.SecureStorageService>(),
          gh<_i42.AudioRecordingService>(),
          gh<_i419.PanicChannelService>(),
          gh<_i705.PanicUploadService>(),
          gh<_i732.TrustedContactService>(),
          gh<_i764.SmsService>(),
          gh<_i655.PanicLocationTracker>(),
          gh<_i519.PanicRepository>(),
        ));
    gh.lazySingleton<_i108.ReportBloc>(
        () => _i108.ReportBloc(gh<_i280.CreateReportUseCase>()));
    gh.factory<_i767.AlertsBloc>(() => _i767.AlertsBloc(
          gh<_i750.GetNotificationsUseCase>(),
          gh<_i748.MarkNotificationsReadUseCase>(),
        ));
    return this;
  }
}

class _$FirebaseModule extends _i1044.FirebaseModule {}

class _$DioModule extends _i197.DioModule {}
