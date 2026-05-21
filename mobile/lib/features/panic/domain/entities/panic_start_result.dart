import 'package:alertaya/features/panic/domain/entities/panic_session_entity.dart';

class PanicStartResult {
  const PanicStartResult({required this.session, required this.uploadUrls});
  final PanicSessionEntity session;
  final List<String> uploadUrls;
}
