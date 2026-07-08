import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/repositories/risk_repository.dart';
import 'package:alertaya/features/risk/presentation/bloc/risk_bloc.dart';

class _MockRiskRepository extends Mock implements RiskRepository {}

void main() {
  late _MockRiskRepository repository;

  const riskInfo = RiskInfo(
    district: 'Miraflores',
    hour: 21,
    riskScore: 72,
    level: 'high',
    topType: 'robbery',
    confidence: 'district-hour',
    badHours: [20, 21, 22],
    nearbyTiles: [],
  );

  setUp(() {
    repository = _MockRiskRepository();
  });

  group('RiskBloc', () {
    blocTest<RiskBloc, RiskState>(
      'emite [RiskLoading, RiskLoaded] cuando el repositorio responde OK',
      setUp: () {
        when(() => repository.getRisk(lat: any(named: 'lat'), lng: any(named: 'lng'), hour: any(named: 'hour')))
            .thenAnswer((_) async => riskInfo);
      },
      build: () => RiskBloc(repository),
      act: (bloc) => bloc.add(const RiskRequested(lat: -12.05, lng: -77.03)),
      expect: () => [
        const RiskLoading(),
        isA<RiskLoaded>().having((s) => s.info, 'info', riskInfo),
      ],
    );

    blocTest<RiskBloc, RiskState>(
      'emite [RiskLoading, RiskFailure] cuando el repositorio falla',
      setUp: () {
        when(() => repository.getRisk(lat: any(named: 'lat'), lng: any(named: 'lng'), hour: any(named: 'hour')))
            .thenThrow(Exception('network error'));
      },
      build: () => RiskBloc(repository),
      act: (bloc) => bloc.add(const RiskRequested(lat: -12.05, lng: -77.03)),
      expect: () => [
        const RiskLoading(),
        isA<RiskFailure>(),
      ],
    );
  });
}
