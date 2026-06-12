import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/profile/data/datasources/me_remote_datasource.dart';
import 'package:alertaya/features/profile/domain/entities/user_profile_entity.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class ProfileEvent {
  const ProfileEvent();
}

class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded();
}

class ProfileMuteToggled extends ProfileEvent {
  const ProfileMuteToggled({required this.mute});
  final bool mute;
}

class ProfileAlertRadiusChanged extends ProfileEvent {
  const ProfileAlertRadiusChanged({required this.meters});
  final int meters;
}

class ProfilePanicRecordAudioToggled extends ProfileEvent {
  const ProfilePanicRecordAudioToggled({required this.enabled});
  final bool enabled;
}

class ProfilePanicAlarmSoundToggled extends ProfileEvent {
  const ProfilePanicAlarmSoundToggled({required this.enabled});
  final bool enabled;
}

// ─── State ────────────────────────────────────────────────────────────────────

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileData extends ProfileState {
  const ProfileData({required this.profile, required this.preferences});
  final UserProfileEntity profile;
  final UserPreferencesEntity preferences;
}

class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);
  final String message;
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._dataSource) : super(const ProfileInitial()) {
    on<ProfileLoaded>(_onLoaded);
    on<ProfileMuteToggled>(_onMuteToggled);
    on<ProfileAlertRadiusChanged>(_onAlertRadiusChanged);
    on<ProfilePanicRecordAudioToggled>(_onPanicRecordAudioToggled);
    on<ProfilePanicAlarmSoundToggled>(_onPanicAlarmSoundToggled);
  }

  final MeRemoteDataSource _dataSource;

  Future<void> _onLoaded(ProfileLoaded event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final results = await Future.wait([
        _dataSource.getProfile(),
        _dataSource.getPreferences(),
      ]);
      emit(ProfileData(
        profile: results[0] as UserProfileEntity,
        preferences: results[1] as UserPreferencesEntity,
      ));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _onMuteToggled(
      ProfileMuteToggled event, Emitter<ProfileState> emit) async {
    final current = state;
    if (current is! ProfileData) return;

    // Optimistic update
    emit(ProfileData(
      profile: current.profile,
      preferences: current.preferences.copyWith(muteNotifications: event.mute),
    ));

    try {
      final updated = await _dataSource.updatePreferences(
        muteNotifications: event.mute,
      );
      emit(ProfileData(profile: current.profile, preferences: updated));
    } catch (_) {
      // Revert on failure
      emit(current);
    }
  }

  Future<void> _onAlertRadiusChanged(
      ProfileAlertRadiusChanged event, Emitter<ProfileState> emit) async {
    final current = state;
    if (current is! ProfileData) return;

    emit(ProfileData(
      profile: current.profile,
      preferences:
          current.preferences.copyWith(alertRadiusMeters: event.meters),
    ));

    try {
      final updated = await _dataSource.updatePreferences(
        alertRadiusMeters: event.meters,
      );
      emit(ProfileData(profile: current.profile, preferences: updated));
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onPanicRecordAudioToggled(
      ProfilePanicRecordAudioToggled event, Emitter<ProfileState> emit) async {
    final current = state;
    if (current is! ProfileData) return;

    emit(ProfileData(
      profile: current.profile,
      preferences:
          current.preferences.copyWith(panicRecordAudio: event.enabled),
    ));

    try {
      final updated = await _dataSource.updatePreferences(
        panicRecordAudio: event.enabled,
      );
      emit(ProfileData(profile: current.profile, preferences: updated));
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onPanicAlarmSoundToggled(
      ProfilePanicAlarmSoundToggled event, Emitter<ProfileState> emit) async {
    final current = state;
    if (current is! ProfileData) return;

    emit(ProfileData(
      profile: current.profile,
      preferences:
          current.preferences.copyWith(panicAlarmSound: event.enabled),
    ));

    try {
      final updated = await _dataSource.updatePreferences(
        panicAlarmSound: event.enabled,
      );
      emit(ProfileData(profile: current.profile, preferences: updated));
    } catch (_) {
      emit(current);
    }
  }
}
