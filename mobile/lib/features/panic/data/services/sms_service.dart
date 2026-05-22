import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Envía un SMS en background a través de SmsManager de Android.
/// No abre diálogo — el mensaje sale silenciosamente.
/// Requiere permiso SEND_SMS en AndroidManifest.xml.
@lazySingleton
class SmsService {
  static const _channel = MethodChannel('com.example.alertaya/panic');

  /// Envía [message] al [phone] sin interfaz de usuario.
  /// Silencia errores para que no bloqueen el flujo de pánico si el
  /// número está vacío o el permiso fue denegado.
  Future<void> send({required String phone, required String message}) async {
    final normalizedPhone = _normalizePhone(phone.trim());
    if (normalizedPhone.isEmpty) return;

    try {
      await _channel.invokeMethod<void>('sendSms', {
        'phone': normalizedPhone,
        'message': message,
      });
      // No loguear el número completo — solo confirmar que salió
      debugPrint('[SmsService] SMS despachado (ver SmsManager logcat para resultado real)');
    } on PlatformException catch (e) {
      debugPrint('[SmsService] Error al enviar SMS — código: ${e.code} | ${e.message}');
    } catch (e) {
      debugPrint('[SmsService] Error inesperado al enviar SMS: $e');
    }
  }

  /// Normaliza el número para que SmsManager lo acepte.
  /// - Elimina espacios, guiones y paréntesis
  /// - Si el número peruano empieza con 9 (celular) y no tiene prefijo,
  ///   agrega +51 automáticamente
  String _normalizePhone(String raw) {
    // Quitar todo lo que no sea dígito o el + inicial
    final digits = raw.replaceAll(RegExp(r'[\s\-().]+'), '');
    if (digits.isEmpty) return '';

    // Ya tiene código de país
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0051')) return '+${digits.substring(2)}';
    if (digits.startsWith('51') && digits.length == 11) return '+$digits';

    // Número local peruano de 9 dígitos → agrega +51
    if (digits.length == 9) return '+51$digits';

    // Otro formato — devolver tal cual y dejar que SmsManager decida
    return digits;
  }
}
