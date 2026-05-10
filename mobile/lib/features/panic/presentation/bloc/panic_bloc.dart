import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/features/panic/domain/entities/panic_session_entity.dart';
import 'package:alertaya/features/panic/domain/usecases/activate_panic_usecase.dart';
import 'package:alertaya/features/panic/domain/usecases/deactivate_panic_usecase.dart';

part 'panic_event.dart';
part 'panic_state.dart';

// Claves de secure storage para la sesión de pánico activa
const _kSessionId = 'panic_session_id';
const _kPin = 'panic_pin';
const _kStartedAt = 'panic_started_at';
const _kLat = 'panic_lat';
const _kLng = 'panic_lng';

@lazySingleton
class PanicBloc extends Bloc<PanicEvent, PanicState> {
  PanicBloc(this._activate, this._deactivate, this._storage)
      : super(const PanicIdle()) {
    on<PanicInitialized>(_onInitialized);
    on<PanicActivationRequested>(_onActivationRequested);
    on<PanicDeactivationRequested>(_onDeactivationRequested);
  }

  final ActivatePanicUseCase _activate;
  final DeactivatePanicUseCase _deactivate;
  final SecureStorageService _storage;

  Future<void> _onInitialized(
      PanicInitialized event, Emitter<PanicState> emit) async {
    final sessionId = await _storage.read(_kSessionId);
    if (sessionId == null) return;

    // Sesión activa encontrada en storage — restaurar estado
    final startedAtStr = await _storage.read(_kStartedAt);
    final latStr = await _storage.read(_kLat);
    final lngStr = await _storage.read(_kLng);

    if (startedAtStr == null || latStr == null || lngStr == null) return;

    emit(PanicActive(
      session: PanicSessionEntity(
        id: sessionId,
        lat: double.parse(latStr),
        lng: double.parse(lngStr),
        startedAt: DateTime.parse(startedAtStr),
      ),
    ));
  }

  Future<void> _onActivationRequested(
    PanicActivationRequested event,
    Emitter<PanicState> emit,
  ) async {
    emit(const PanicActivating());

    final result = await _activate(
      ActivatePanicParams(lat: event.lat, lng: event.lng),
    );

    await result.fold(
      (failure) async => emit(PanicError(failure.toString())),
      (session) async {
        // Persistir sesión y PIN en secure storage
        await Future.wait([
          _storage.write(_kSessionId, session.id),
          _storage.write(_kPin, event.pin),
          _storage.write(_kStartedAt, session.startedAt.toIso8601String()),
          _storage.write(_kLat, session.lat.toString()),
          _storage.write(_kLng, session.lng.toString()),
        ]);
        emit(PanicActive(session: session));
      },
    );
  }

  Future<void> _onDeactivationRequested(
    PanicDeactivationRequested event,
    Emitter<PanicState> emit,
  ) async {
    if (state is! PanicActive) return;
    final current = state as PanicActive;

    if (current.isPinLocked) return;

    // Verificar PIN contra el almacenado
    final storedPin = await _storage.read(_kPin);
    if (storedPin != event.pin) {
      final newAttempts = current.failedPinAttempts + 1;
      emit(current.copyWith(failedPinAttempts: newAttempts));
      return;
    }

    emit(const PanicDeactivating());

    final result = await _deactivate(current.session.id);

    await result.fold(
      (failure) async => emit(PanicError(failure.toString())),
      (_) async {
        await _storage.deleteAll(
            [_kSessionId, _kPin, _kStartedAt, _kLat, _kLng]);
        emit(const PanicIdle());
      },
    );
  }
}
