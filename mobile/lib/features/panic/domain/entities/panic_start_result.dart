import 'package:alertaya/features/panic/domain/entities/panic_session_entity.dart';

/// Parámetros para upload directo a Cloudinary desde el cliente.
/// El API firma cada bloque con su propio timestamp+signature para que
/// Flutter pueda subir el audio cifrado sin exponer el api_secret.
class CloudinaryUploadParams {
  const CloudinaryUploadParams({
    required this.uploadUrl,
    required this.publicId,
    required this.timestamp,
    required this.apiKey,
    required this.signature,
  });

  final String uploadUrl;
  final String publicId;
  final int timestamp;
  final String apiKey;
  final String signature;

  factory CloudinaryUploadParams.fromJson(Map<String, dynamic> json) =>
      CloudinaryUploadParams(
        uploadUrl: json['uploadUrl'] as String,
        publicId: json['publicId'] as String,
        timestamp: json['timestamp'] as int,
        apiKey: json['apiKey'] as String,
        signature: json['signature'] as String,
      );
}

class PanicStartResult {
  const PanicStartResult({required this.session, required this.uploadParams});
  final PanicSessionEntity session;
  final List<CloudinaryUploadParams> uploadParams;
}
