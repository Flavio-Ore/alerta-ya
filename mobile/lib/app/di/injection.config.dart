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
import 'package:alertaya/features/auth/domain/usecases/is_first_launch_usecase.dart'
    as _i586;
import 'package:alertaya/features/auth/domain/usecases/sign_in_with_email_usecase.dart'
    as _i351;
import 'package:alertaya/features/auth/domain/usecases/sign_out_usecase.dart'
    as _i290;
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart'
    as _i70;
import 'package:alertaya/features/map/data/datasources/mock_incident_datasource.dart'
    as _i317;
import 'package:alertaya/features/map/data/repositories/mock_incident_repository.dart'
    as _i506;
import 'package:alertaya/features/map/domain/repositories/incident_repository.dart'
    as _i118;
import 'package:alertaya/features/map/domain/usecases/confirm_incident_usecase.dart'
    as _i327;
import 'package:alertaya/features/map/domain/usecases/get_active_incidents_usecase.dart'
    as _i618;
import 'package:alertaya/features/map/presentation/bloc/map_bloc.dart' as _i670;
import 'package:alertaya/features/report/data/repositories/mock_report_repository.dart'
    as _i594;
import 'package:alertaya/features/report/domain/repositories/report_repository.dart'
    as _i658;
import 'package:alertaya/features/report/domain/usecases/create_report_usecase.dart'
    as _i280;
import 'package:alertaya/features/report/domain/usecases/get_form_schema_usecase.dart'
    as _i638;
import 'package:alertaya/features/report/presentation/bloc/report_bloc.dart'
    as _i108;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
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
    gh.lazySingleton<_i895.Connectivity>(() => dioModule.connectivity);
    gh.lazySingleton<_i361.Dio>(() => dioModule.dio());
    gh.lazySingleton<_i317.MockIncidentDatasource>(
        () => _i317.MockIncidentDatasource());
    gh.lazySingleton<_i118.IncidentRepository>(
        () => _i506.MockIncidentRepository(gh<_i317.MockIncidentDatasource>()));
    gh.lazySingleton<_i658.ReportRepository>(
        () => _i594.MockReportRepository());
    gh.lazySingleton<_i852.OnboardingLocalDataSource>(
        () => _i852.OnboardingLocalDataSourceImpl());
    gh.factory<_i280.CreateReportUseCase>(
        () => _i280.CreateReportUseCase(gh<_i658.ReportRepository>()));
    gh.factory<_i638.GetFormSchemaUseCase>(
        () => _i638.GetFormSchemaUseCase(gh<_i658.ReportRepository>()));
    gh.lazySingleton<_i857.NetworkInfo>(
        () => _i857.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i327.ConfirmIncidentUseCase>(
        () => _i327.ConfirmIncidentUseCase(gh<_i118.IncidentRepository>()));
    gh.lazySingleton<_i618.GetActiveIncidentsUseCase>(
        () => _i618.GetActiveIncidentsUseCase(gh<_i118.IncidentRepository>()));
    gh.lazySingleton<_i108.ReportBloc>(
        () => _i108.ReportBloc(gh<_i280.CreateReportUseCase>()));
    gh.lazySingleton<_i781.FirebaseAuthDataSource>(
        () => _i781.FirebaseAuthDataSourceImpl(gh<_i59.FirebaseAuth>()));
    gh.factory<_i670.MapBloc>(() => _i670.MapBloc(
          gh<_i618.GetActiveIncidentsUseCase>(),
          gh<_i327.ConfirmIncidentUseCase>(),
        ));
    gh.lazySingleton<_i576.AuthRepository>(() => _i779.AuthRepositoryImpl(
          gh<_i781.FirebaseAuthDataSource>(),
          gh<_i852.OnboardingLocalDataSource>(),
        ));
    gh.factory<_i401.CompleteOnboardingUseCase>(
        () => _i401.CompleteOnboardingUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i586.IsFirstLaunchUseCase>(
        () => _i586.IsFirstLaunchUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i351.SignInWithEmailUseCase>(
        () => _i351.SignInWithEmailUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i290.SignOutUseCase>(
        () => _i290.SignOutUseCase(gh<_i576.AuthRepository>()));
    gh.factory<_i70.AuthBloc>(() => _i70.AuthBloc(
          gh<_i351.SignInWithEmailUseCase>(),
          gh<_i290.SignOutUseCase>(),
          gh<_i586.IsFirstLaunchUseCase>(),
          gh<_i401.CompleteOnboardingUseCase>(),
          gh<_i576.AuthRepository>(),
        ));
    return this;
  }
}

class _$FirebaseModule extends _i1044.FirebaseModule {}

class _$DioModule extends _i197.DioModule {}
