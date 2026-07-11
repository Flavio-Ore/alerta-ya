import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/core/utils/encryption_util.dart';
import 'package:alertaya/features/panic/data/services/escrow_confirmation_guard.dart';
import 'package:alertaya/features/panic/data/services/escrow_key_submitter.dart';

const _kEncryptionKey = 'panic_recording_key';

/// Maneja grabación de audio en bloques de 10 min cifrados con AES-256.
/// Ciclo de vida: start() → N bloques automáticos → stop()
@lazySingleton
class AudioRecordingService {
  AudioRecordingService(this._storage, this._escrowSubmitter);

  final SecureStorageService _storage;
  final EscrowKeySubmitter _escrowSubmitter;
  final _recorder = AudioRecorder();

  // Stream de amplitud para la UI — emite cada 100ms
  final _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  // Stream de bloque completado — el BLoC escucha para actualizar currentBlock
  final _blockController = StreamController<String>.broadcast();
  Stream<String> get blockCompletedStream => _blockController.stream;

  Timer? _blockTimer;
  Timer? _amplitudeTimer;
  String? _sessionId;
  int _blockNumber = 0;
  bool _isRecording = false;
  late Uint8List _encryptionKey;
  final _escrowGuard = EscrowConfirmationGuard();

  bool get isRecording => _isRecording;

  /// Inicia la grabación. Llama a [_startBlock] inmediatamente y
  /// programa la rotación cada [AppConstants.panicBlockMinutes] minutos.
  Future<void> start(String sessionId) async {
    if (_isRecording) return;
    _sessionId = sessionId;
    _blockNumber = 0;
    _isRecording = true;
    // resetFor invalida cualquier tarea de escrow huérfana de una sesión
    // anterior: si esa tarea resuelve más tarde, su resultado ya no podrá
    // marcar como confirmada la clave de ESTA sesión.
    _escrowGuard.resetFor(sessionId);

    // Clave AES-256 nueva por sesión — nunca se reutiliza entre pánicos.
    _encryptionKey = EncryptionUtil.generateKey();
    await _storage.write(_kEncryptionKey, base64Encode(_encryptionKey));

    // Escrow en paralelo: no bloquea el inicio de la grabación (emergencia
    // primero), pero stop() no borra la clave hasta que esto confirme.
    unawaited(_submitEscrowKey(sessionId));

    await _startBlock();

    // Rotar bloque cada 10 minutos
    _blockTimer = Timer.periodic(
      const Duration(minutes: AppConstants.panicBlockMinutes),
      (_) => _rotateBlock(),
    );

    // Emitir amplitud cada 100ms
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _emitAmplitude(),
    );
  }

  /// Lanza el envío de escrow para [sessionId], capturado como parámetro
  /// (no releído de [_sessionId] al resolver) para que el guard pueda
  /// detectar si sigue siendo la sesión activa cuando la tarea termine.
  Future<void> _submitEscrowKey(String sessionId) {
    return _escrowGuard.submit(
      sessionId,
      () => _escrowSubmitter.submit(sessionId: sessionId, aesKey: _encryptionKey),
    );
  }

  /// Detiene la grabación, cifra el último bloque y limpia recursos.
  /// Ya no borra la clave — eso queda para [confirmUploadsAndClearKey].
  Future<List<String>> stop() async {
    if (!_isRecording) return [];
    _isRecording = false;

    _blockTimer?.cancel();
    _amplitudeTimer?.cancel();
    _blockTimer = null;
    _amplitudeTimer = null;

    final path = await _stopCurrentBlock();

    _amplitudeController.add(0.0);

    final paths = <String>[];
    if (path != null) paths.add(path);
    return paths;
  }

  /// Se llama después de confirmar que todos los bloques de audio subieron.
  /// Reintenta el escrow una vez más si aún no fue confirmado; solo borra
  /// la clave local si el escrow terminó confirmado — si no, la clave
  /// permanece en secure storage para un reintento en una futura sesión.
  Future<void> confirmUploadsAndClearKey() async {
    final sessionId = _sessionId!;
    if (!_escrowGuard.confirmed) {
      // Si el envío en segundo plano lanzado por start() todavía está en
      // curso para ESTA sesión, el guard reutiliza esa misma tarea en vez
      // de disparar una llamada de red duplicada al backend de escrow.
      await _escrowGuard.submit(
        sessionId,
        () => _escrowSubmitter.submit(
          sessionId: sessionId,
          aesKey: _encryptionKey,
          attempts: 1,
        ),
      );
    }
    if (_escrowGuard.confirmed) {
      await _storage.delete(_kEncryptionKey);
    } else {
      debugPrint(
        '[AudioRecordingService] escrow NO confirmado — clave permanece en secure storage',
      );
    }
  }

  Future<void> dispose() async {
    await stop();
    await _amplitudeController.close();
    await _blockController.close();
    await _recorder.dispose();
  }

  // ── Privados ────────────────────────────────────────────────────────────────

  Future<void> _startBlock() async {
    _blockNumber++;
    final dir = await getApplicationDocumentsDirectory();
    final rawPath =
        '${dir.path}/panic_${_sessionId}_block${_blockNumber}_raw.aac';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        // Mono: menor tamaño de archivo, reduce captación de la alarma
        numChannels: 1,
        // Filtros de Android AcousticEchoCanceler / NoiseSuppressor
        // para atenuar el sonido de alarma del altavoz en la grabación
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      ),
      path: rawPath,
    );
  }

  Future<String?> _stopCurrentBlock() async {
    final isRec = await _recorder.isRecording();
    debugPrint('[AudioRecording] _stopCurrentBlock — isRecording=$isRec');
    if (!isRec) return null;

    final rawPath = await _recorder.stop();
    debugPrint('[AudioRecording] recorder.stop() → $rawPath');
    if (rawPath == null) return null;

    final rawFile = File(rawPath);
    final rawSize = rawFile.existsSync() ? rawFile.lengthSync() : -1;
    debugPrint('[AudioRecording] Raw AAC size: $rawSize bytes');

    // Cifrar el bloque grabado con AES-256
    final rawBytes = await rawFile.readAsBytes();
    final encrypted = EncryptionUtil.encrypt(rawBytes, _encryptionKey);

    final encPath = rawPath.replaceFirst('_raw.aac', '_enc.bin');
    await File(encPath).writeAsBytes(encrypted);
    debugPrint('[AudioRecording] Cifrado OK → $encPath (${encrypted.length} bytes)');

    // Eliminar el archivo raw para no dejar audio sin cifrar en disco
    await rawFile.delete();

    return encPath;
  }

  Future<void> _rotateBlock() async {
    final completedPath = await _stopCurrentBlock();
    if (completedPath != null) {
      _blockController.add(completedPath);
    }
    // Solo continuar si aún debemos grabar
    // (máximo 6 bloques = 60 min según CONSTRAINTS.md)
    if (_blockNumber <
        AppConstants.panicMaxRecordingMinutes ~/
            AppConstants.panicBlockMinutes) {
      await _startBlock();
    } else {
      _isRecording = false;
      _blockTimer?.cancel();
    }
  }

  Future<void> _emitAmplitude() async {
    if (!await _recorder.isRecording()) {
      _amplitudeController.add(0.0);
      return;
    }
    final amp = await _recorder.getAmplitude();
    // Normalizar de dBFS (−160 a 0) a 0.0–1.0
    final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
    _amplitudeController.add(normalized);
  }
}
