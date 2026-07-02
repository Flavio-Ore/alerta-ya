import 'package:alertaya/features/risk/domain/entities/risk_info.dart';

abstract class RiskRepository {
  Future<RiskInfo> getRisk({
    required double lat,
    required double lng,
    int? hour,
  });
}
