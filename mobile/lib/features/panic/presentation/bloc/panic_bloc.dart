import 'dart:async' show StreamSubscription, unawaited;
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/features/panic/data/services/audio_recording_service.dart';
import 'package:alertaya/features/panic/data/services/panic_channel_service.dart';
import 'package:alertaya/features/panic/data/services/panic_upload_service.dart';
import 'package:alertaya/features/panic/data/services/sms_service.dart';
import 'package:alertaya/features/panic/data/services/trusted_contact_service.dart';
import 'package:alertaya/features/panic/domain/entities/panic_session_entity.dart';
import 'package:alertaya/features/panic/domain/entities/panic_start_result.dart';
import 'package:alertaya/features/panic/domain/usecases/activate_panic_usecase.dart';
import 'package:alertaya/features/panic/domain/usecases/deactivate_panic_usecase.dart';

part 'panic_event.dart';
part 'panic_state.dart';

// Claves de secure storage para la sesión de pánico activa
const _kSessionId = 'panic_session_id';
const _kSavedPin = 'panic_saved_pin'; // persiste entre sesiones
const _kStartedAt = 'panic_started_at';
const _kLat = 'panic_lat';
const _kLng = 'panic_lng';
const _kFailedAttempts = 'panic_failed_attempts';
const _kUploadUrls = 'panic_upload_urls';
const _kRecordAudio = 'panic_record_audio';
const _kAlarmSound = 'panic_alarm_sound';

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
    this._smsService,
  ) : super(const PanicIdle()) {
    on<PanicInitialized>(_onInitialized);
    on<PanicActivationRequested>(_onActivationRequested);
    on<PanicDeactivationRequested>(_onDeactivationRequested);
    on<PanicSavedPinUpdated>(_onSavedPinUpdated);
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
  final SmsService _smsService;

  StreamSubscription<double>? _amplitudeSub;
  StreamSubscription<String>? _blockSub;
  List<CloudinaryUploadParams> _uploadParams = [];

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

    final uploadParamsStr = await _storage.read(_kUploadUrls);
    if (uploadParamsStr != null) {
      _uploadParams = (jsonDecode(uploadParamsStr) as List<dynamic>)
          .map((e) => CloudinaryUploadParams.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final session = PanicSessionEntity(
      id: sessionId,
      lat: double.parse(latStr),
      lng: double.parse(lngStr),
      startedAt: DateTime.parse(startedAtStr),
    );

    final contact = await _contactService.getContact();
    // Restaurar flags de la sesión activa — defaults true por seguridad
    final recordAudio = (await _storage.read(_kRecordAudio)) != 'false';
    final alarmSound = (await _storage.read(_kAlarmSound)) != 'false';
    emit(PanicActive(
      session: session,
      failedPinAttempts: failedAttempts,
      trustedContactName: contact?.name,
      recordAudio: recordAudio,
      alarmSound: alarmSound,
    ));
    // Retomar grabación si la app se cerró con pánico activo
    await _startRecording(
      session.id,
      session.startedAt,
      recordAudio: recordAudio,
      alarmSound: alarmSound,
    );
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
        _uploadParams = startResult.uploadParams;
        final contact = await _contactService.getContact();
        final paramsJson = jsonEncode(
          _uploadParams.map((p) => {
            'uploadUrl': p.uploadUrl,
            'publicId': p.publicId,
            'timestamp': p.timestamp,
            'apiKey': p.apiKey,
            'signature': p.signature,
          }).toList(),
        );
        await Future.wait([
          _storage.write(_kSessionId, startResult.session.id),
          _storage.write(_kStartedAt, startResult.session.startedAt.toIso8601String()),
          _storage.write(_kLat, startResult.session.lat.toString()),
          _storage.write(_kLng, startResult.session.lng.toString()),
          _storage.write(_kUploadUrls, paramsJson),
          _storage.write(_kRecordAudio, event.recordAudio.toString()),
          _storage.write(_kAlarmSound, event.alarmSound.toString()),
          // Solo actualiza el PIN guardado si se provee uno nuevo.
          if (event.pin != null) _storage.write(_kSavedPin, _hashPin(event.pin!)),
        ]);
        emit(PanicActive(
          session: startResult.session,
          trustedContactName: contact?.name,
          recordAudio: event.recordAudio,
          alarmSound: event.alarmSound,
        ));
        await _startRecording(
          startResult.session.id,
          startResult.session.startedAt,
          recordAudio: event.recordAudio,
          alarmSound: event.alarmSound,
        );
        // Enviar SMS automático al contacto de confianza — fire-and-forget,
        // no interrumpe el flujo de pánico si falla o si no hay contacto.
        unawaited(_sendEmergencySms(contact, startResult.session));
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

    final storedPin = await _storage.read(_kSavedPin);
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
        _uploadParams = [];
        await _storage.deleteAll([
          _kSessionId,
          _kStartedAt,
          _kLat,
          _kLng,
          _kFailedAttempts,
          _kUploadUrls,
          _kRecordAudio,
          _kAlarmSound,
          // _kSavedPin se omite: persiste para la próxima activación
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
    debugPrint('[PanicBloc] Bloque completado: currentBlock=${current.session.currentBlock} urlIndex=$urlIndex uploadParams=${_uploadParams.length}');
    if (urlIndex >= 0 && urlIndex < _uploadParams.length) {
      // Fire-and-forget: el bloque siguiente graba mientras este se sube
      unawaited(
        _uploadService
            .uploadBlock(_uploadParams[urlIndex], event.filePath)
            .catchError((dynamic e) {
          debugPrint('[PanicBloc] Upload bloque $urlIndex falló: $e');
        }),
      );
    } else {
      debugPrint('[PanicBloc] SKIP upload — urlIndex=$urlIndex fuera de rango (${_uploadParams.length} slots)');
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

  Future<void> _sendEmergencySms(
    TrustedContact? contact,
    PanicSessionEntity session,
  ) async {
    if (contact == null || contact.phone.trim().isEmpty) return;
    final mapsUrl =
        'https://maps.google.com/?q=${session.lat},${session.lng}';
    // Mensaje enviado al contacto de confianza — no incluye identidad del
    // usuario para cumplir con SECURITY_RULES.md (no exponer datos personales)
    const message =
        '🚨 [AlertaYa] Se activó el botón de pánico de emergencia. '
        'Por favor comunicate de inmediato.';
    await _smsService.send(phone: contact.phone, message: '$message\n$mapsUrl');
  }

  Future<void> _startRecording(
    String sessionId,
    DateTime startedAt, {
    required bool recordAudio,
    required bool alarmSound,
  }) async {
    // GPS y foreground service SIEMPRE corren — son obligatorios para que el
    // panel autoridades reciba la sesión. Solo la grabación y la alarma respetan flags.
    if (recordAudio) {
      await _audioService.start(sessionId);
      _amplitudeSub = _audioService.amplitudeStream.listen(
        (amp) => add(_PanicAmplitudeUpdated(amp)),
      );
      _blockSub = _audioService.blockCompletedStream.listen(
        (path) => add(_PanicBlockCompleted(path)),
      );
    }

    final initialElapsed = DateTime.now().difference(startedAt).inSeconds;
    await _channelService.startService(
      initialElapsed,
      alarmSound: alarmSound,
    );
  }

  Future<void> _stopRecording([PanicActive? activeState]) async {
    await _amplitudeSub?.cancel();
    await _blockSub?.cancel();
    _amplitudeSub = null;
    _blockSub = null;

    final finalPaths = await _audioService.stop();
    debugPrint('[PanicBloc] _stopRecording — finalPaths: $finalPaths | uploadParams: ${_uploadParams.length}');

    // Subir el bloque parcial final si la desactivación fue intencional
    if (activeState != null && finalPaths.isNotEmpty) {
      final urlIndex = activeState.session.currentBlock - 1;
      debugPrint('[PanicBloc] Subiendo bloque parcial final — urlIndex=$urlIndex');
      if (urlIndex >= 0 && urlIndex < _uploadParams.length) {
        try {
          await _uploadService
              .uploadBlock(_uploadParams[urlIndex], finalPaths.first)
              .timeout(const Duration(seconds: 30));
          debugPrint('[PanicBloc] Upload bloque parcial OK');
        } catch (e) {
          debugPrint('[PanicBloc] Upload bloque parcial FALLÓ: $e');
        }
      } else {
        debugPrint('[PanicBloc] SKIP upload parcial — urlIndex=$urlIndex fuera de rango');
      }
    } else {
      debugPrint('[PanicBloc] SKIP upload parcial — activeState=$activeState finalPaths=$finalPaths');
    }

    await _channelService.stopService();
  }

  Future<bool> hasSavedPin() async =>
      (await _storage.read(_kSavedPin)) != null;

  Future<void> _onSavedPinUpdated(
    PanicSavedPinUpdated event,
    Emitter<PanicState> emit,
  ) async {
    await _storage.write(_kSavedPin, _hashPin(event.pin));
  }

  String _hashPin(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  @override
  Future<void> close() async {
    await _stopRecording();
    return super.close();
  }
}
