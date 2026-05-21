import 'dart:async' show StreamSubscription, unawaited;
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/features/panic/data/services/audio_recording_service.dart';
import 'package:alertaya/features/panic/data/services/panic_channel_service.dart';
import 'package:alertaya/features/panic/data/services/panic_upload_service.dart';
import 'package:alertaya/features/panic/data/services/trusted_contact_service.dart';
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
const _kFailedAttempts = 'panic_failed_attempts';
const _kUploadUrls = 'panic_upload_urls';

@lazySingleton
class PanicBloc extends Bloc<PanicEvent, PanicState> {
  PanicBloc(
    this._activate,
    this._deactivate,
    this._storage,
    this._audioService,
    this._channelService,
    this._uploadService,
    this._contactService,
  ) : super(const PanicIdle()) {
    on<PanicInitialized>(_onInitialized);
    on<PanicActivationRequested>(_onActivationRequested);
    on<PanicDeactivationRequested>(_onDeactivationRequested);
    // Eventos internos del servicio de grabación
    on<_PanicAmplitudeUpdated>(_onAmplitudeUpdated);
    on<_PanicBlockCompleted>(_onBlockCompleted);
  }

  final ActivatePanicUseCase _activate;
  final DeactivatePanicUseCase _deactivate;
  final SecureStorageService _storage;
  final AudioRecordingService _audioService;
  final PanicChannelService _channelService;
  final PanicUploadService _uploadService;
  final TrustedContactService _contactService;

  StreamSubscription<double>? _amplitudeSub;
  StreamSubscription<String>? _blockSub;
  List<String> _uploadUrls = [];

  Future<void> _onInitialized(
    PanicInitialized event,
    Emitter<PanicState> emit,
  ) async {
    final sessionId = await _storage.read(_kSessionId);
    if (sessionId == null) return;

    final startedAtStr = await _storage.read(_kStartedAt);
    final latStr = await _storage.read(_kLat);
    final lngStr = await _storage.read(_kLng);
    if (startedAtStr == null || latStr == null || lngStr == null) return;

    final failedStr = await _storage.read(_kFailedAttempts);
    final failedAttempts = int.tryParse(failedStr ?? '0') ?? 0;

    final uploadUrlsStr = await _storage.read(_kUploadUrls);
    if (uploadUrlsStr != null) {
      _uploadUrls =
          List<String>.from(jsonDecode(uploadUrlsStr) as List<dynamic>);
    }

    final session = PanicSessionEntity(
      id: sessionId,
      lat: double.parse(latStr),
      lng: double.parse(lngStr),
      startedAt: DateTime.parse(startedAtStr),
    );

    final contact = await _contactService.getContact();
    emit(PanicActive(
      session: session,
      failedPinAttempts: failedAttempts,
      trustedContactName: contact?.name,
    ));
    // Retomar grabación si la app se cerró con pánico activo
    await _startRecording(session.id, session.startedAt);
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
      (startResult) async {
        _uploadUrls = startResult.uploadUrls;
        final contact = await _contactService.getContact();
        await Future.wait([
          _storage.write(_kSessionId, startResult.session.id),
          _storage.write(_kPin, _hashPin(event.pin)),
          _storage.write(_kStartedAt, startResult.session.startedAt.toIso8601String()),
          _storage.write(_kLat, startResult.session.lat.toString()),
          _storage.write(_kLng, startResult.session.lng.toString()),
          _storage.write(_kUploadUrls, jsonEncode(_uploadUrls)),
        ]);
        emit(PanicActive(
          session: startResult.session,
          trustedContactName: contact?.name,
        ));
        await _startRecording(startResult.session.id, startResult.session.startedAt);
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

    final storedPin = await _storage.read(_kPin);
    if (storedPin != _hashPin(event.pin)) {
      final newAttempts = current.failedPinAttempts + 1;
      await _storage.write(_kFailedAttempts, newAttempts.toString());
      emit(current.copyWith(failedPinAttempts: newAttempts));
      return;
    }

    emit(const PanicDeactivating());
    await _stopRecording(current);

    final result = await _deactivate(current.session.id);

    await result.fold(
      (failure) async => emit(PanicError(failure.toString())),
      (_) async {
        _uploadUrls = [];
        await _storage.deleteAll([
          _kSessionId,
          _kPin,
          _kStartedAt,
          _kLat,
          _kLng,
          _kFailedAttempts,
          _kUploadUrls,
        ]);
        emit(const PanicIdle());
      },
    );
  }

  void _onAmplitudeUpdated(
    _PanicAmplitudeUpdated event,
    Emitter<PanicState> emit,
  ) {
    if (state is PanicActive) {
      emit((state as PanicActive).copyWith(amplitude: event.amplitude));
    }
  }

  void _onBlockCompleted(
    _PanicBlockCompleted event,
    Emitter<PanicState> emit,
  ) {
    if (state is! PanicActive) return;
    final current = state as PanicActive;

    final urlIndex = current.session.currentBlock - 1;
    if (urlIndex >= 0 && urlIndex < _uploadUrls.length) {
      // Fire-and-forget: el bloque siguiente graba mientras este se sube
      unawaited(
        _uploadService
            .uploadBlock(_uploadUrls[urlIndex], event.filePath)
            .catchError((_) {}),
      );
    }

    final updatedPaths = [...current.session.recordingPaths, event.filePath];
    emit(current.copyWith(
      session: current.session.copyWith(
        recordingPaths: updatedPaths,
        currentBlock: current.session.currentBlock + 1,
      ),
    ));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _startRecording(String sessionId, DateTime startedAt) async {
    await _audioService.start(sessionId);
    final initialElapsed = DateTime.now().difference(startedAt).inSeconds;
    await _channelService.startService(initialElapsed);

    _amplitudeSub = _audioService.amplitudeStream.listen(
      (amp) => add(_PanicAmplitudeUpdated(amp)),
    );
    _blockSub = _audioService.blockCompletedStream.listen(
      (path) => add(_PanicBlockCompleted(path)),
    );
  }

  Future<void> _stopRecording([PanicActive? activeState]) async {
    await _amplitudeSub?.cancel();
    await _blockSub?.cancel();
    _amplitudeSub = null;
    _blockSub = null;

    final finalPaths = await _audioService.stop();

    // Subir el bloque parcial final si la desactivación fue intencional
    if (activeState != null && finalPaths.isNotEmpty) {
      final urlIndex = activeState.session.currentBlock - 1;
      if (urlIndex >= 0 && urlIndex < _uploadUrls.length) {
        try {
          await _uploadService
              .uploadBlock(_uploadUrls[urlIndex], finalPaths.first)
              .timeout(const Duration(seconds: 10));
        } catch (_) {}
      }
    }

    await _channelService.stopService();
  }

  String _hashPin(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  @override
  Future<void> close() async {
    await _stopRecording();
    return super.close();
  }
}
