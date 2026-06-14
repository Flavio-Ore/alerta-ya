import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/core/utils/encryption_util.dart';

const _kVideoEncryptionKey = 'panic_video_encryption_key';

/// Graba video en bloques de 2 min cifrados con AES-256.
/// Usa la cámara trasera sin preview visible (widget 1×1 anclado en la UI).
/// Ciclo de vida: start() → N clips automáticos → stop()
@lazySingleton
class VideoRecordingService {
  VideoRecordingService(this._storage);

  final SecureStorageService _storage;

  CameraController? _controller;

  final _clipController = StreamController<String>.broadcast();
  Stream<String> get clipCompletedStream => _clipController.stream;

  Timer? _clipTimer;
  String? _sessionId;
  int _clipNumber = 0;
  bool _isRecording = false;
  late Uint8List _encryptionKey;

  bool get isRecording => _isRecording;

  /// Widget de 1×1 px que ancla la textura de cámara en el árbol de widgets.
  /// Debe estar en el árbol mientras se graba — sin él la sesión de cámara no
  /// sobrevive en background (Android destruye la Surface si no hay consumidor).
  Widget buildPreview() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return const SizedBox.shrink();
    return SizedBox(width: 1, height: 1, child: CameraPreview(ctrl));
  }

  /// Inicia grabación de video. Llama a [_startClip] inmediatamente y
  /// programa la rotación cada [AppConstants.panicVideoClipMinutes] minutos.
  Future<void> start(String sessionId) async {
    if (_isRecording) return;
    _sessionId = sessionId;
    _clipNumber = 0;
    _isRecording = true;

    // Generar o recuperar clave AES-256 de esta sesión
    final stored = await _storage.read(_kVideoEncryptionKey);
    if (stored != null) {
      _encryptionKey = Uint8List.fromList(base64Decode(stored));
    } else {
      _encryptionKey = EncryptionUtil.generateKey();
      await _storage.write(_kVideoEncryptionKey, base64Encode(_encryptionKey));
    }

    // Inicializar cámara trasera a 720p sin audio
    // (la alarma contaminaría el audio; el valor de este modo es imagen del agresor)
    final cameras = await availableCameras();
    final rear = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      rear,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();

    await _startClip();

    _clipTimer = Timer.periodic(
      Duration(minutes: AppConstants.panicVideoClipMinutes),
      (_) => _rotateClip(),
    );
  }

  /// Detiene la grabación, cifra el último clip y limpia recursos.
  Future<List<String>> stop() async {
    if (!_isRecording) return [];
    _isRecording = false;

    _clipTimer?.cancel();
    _clipTimer = null;

    final path = await _stopCurrentClip();
    await _storage.delete(_kVideoEncryptionKey);
    await _controller?.dispose();
    _controller = null;

    final paths = <String>[];
    if (path != null) paths.add(path);
    return paths;
  }

  Future<void> dispose() async {
    await stop();
    await _clipController.close();
  }

  // ── Privados ─────────────────────────────────────────────────────────────────

  Future<void> _startClip() async {
    _clipNumber++;
    await _controller!.startVideoRecording();
    debugPrint('[VideoRecording] Clip $_clipNumber iniciado');
  }

  Future<String?> _stopCurrentClip() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isRecordingVideo) return null;

    XFile xfile;
    try {
      xfile = await ctrl.stopVideoRecording();
    } catch (e) {
      debugPrint('[VideoRecording] Error al detener clip: $e');
      return null;
    }
    debugPrint('[VideoRecording] Clip detenido → ${xfile.path}');

    final rawFile = File(xfile.path);
    if (!rawFile.existsSync()) return null;

    final rawBytes = await rawFile.readAsBytes();
    final encrypted = EncryptionUtil.encrypt(rawBytes, _encryptionKey);

    final dir = await getApplicationDocumentsDirectory();
    final encPath =
        '${dir.path}/panic_${_sessionId}_video_clip${_clipNumber}_enc.bin';
    await File(encPath).writeAsBytes(encrypted);
    debugPrint(
        '[VideoRecording] Cifrado OK → $encPath (${encrypted.length} bytes)');

    await rawFile.delete();
    return encPath;
  }

  Future<void> _rotateClip() async {
    final completedPath = await _stopCurrentClip();
    if (completedPath != null) {
      _clipController.add(completedPath);
    }
    if (_clipNumber < AppConstants.panicMaxVideoClips) {
      await _startClip();
    } else {
      _isRecording = false;
      _clipTimer?.cancel();
    }
  }
}
