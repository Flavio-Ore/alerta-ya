import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/core/utils/encryption_util.dart';

const _kEncryptionKey = 'panic_recording_key';

/// Maneja grabación de audio en bloques de 10 min cifrados con AES-256.
/// Ciclo de vida: start() → N bloques automáticos → stop()
@lazySingleton
class AudioRecordingService {
  AudioRecordingService(this._storage);

  final SecureStorageService _storage;
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

  bool get isRecording => _isRecording;

  /// Inicia la grabación. Llama a [_startBlock] inmediatamente y
  /// programa la rotación cada [AppConstants.panicBlockMinutes] minutos.
  Future<void> start(String sessionId) async {
    if (_isRecording) return;
    _sessionId = sessionId;
    _blockNumber = 0;
    _isRecording = true;

    // Generar o recuperar clave AES-256 de esta sesión
    final stored = await _storage.read(_kEncryptionKey);
    if (stored != null) {
      _encryptionKey = Uint8List.fromList(
        stored.codeUnits,
      );
    } else {
      _encryptionKey = EncryptionUtil.generateKey();
      await _storage.write(
        _kEncryptionKey,
        String.fromCharCodes(_encryptionKey),
      );
    }

    await _startBlock();

    // Rotar bloque cada 10 minutos
    _blockTimer = Timer.periodic(
      Duration(minutes: AppConstants.panicBlockMinutes),
      (_) => _rotateBlock(),
    );

    // Emitir amplitud cada 100ms
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _emitAmplitude(),
    );
  }

  /// Detiene la grabación, cifra el último bloque y limpia recursos.
  Future<List<String>> stop() async {
    if (!_isRecording) return [];
    _isRecording = false;

    _blockTimer?.cancel();
    _amplitudeTimer?.cancel();
    _blockTimer = null;
    _amplitudeTimer = null;

    final path = await _stopCurrentBlock();
    await _storage.delete(_kEncryptionKey);

    _amplitudeController.add(0.0);

    final paths = <String>[];
    if (path != null) paths.add(path);
    return paths;
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
      ),
      path: rawPath,
    );
  }

  Future<String?> _stopCurrentBlock() async {
    if (!await _recorder.isRecording()) return null;
    final rawPath = await _recorder.stop();
    if (rawPath == null) return null;

    // Cifrar el bloque grabado con AES-256
    final rawBytes = await File(rawPath).readAsBytes();
    final encrypted = EncryptionUtil.encrypt(rawBytes, _encryptionKey);

    final encPath = rawPath.replaceFirst('_raw.aac', '_enc.bin');
    await File(encPath).writeAsBytes(encrypted);

    // Eliminar el archivo raw para no dejar audio sin cifrar en disco
    await File(rawPath).delete();

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
