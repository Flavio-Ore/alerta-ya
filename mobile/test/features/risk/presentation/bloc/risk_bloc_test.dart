import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/entities/risk_prediction.dart';
import 'package:alertaya/features/risk/domain/repositories/risk_repository.dart';
import 'package:alertaya/features/risk/presentation/bloc/risk_bloc.dart';

class _MockRiskRepository extends Mock implements RiskRepository {}

RiskPrediction _prediction({required int dayOfWeek, int? score}) => RiskPrediction(
      available: score != null,
      hour: 21,
      dayOfWeek: dayOfWeek,
      riskScore: score,
    );

void main() {
  late _MockRiskRepository repository;

  const riskInfo = RiskInfo(
    district: 'Miraflores',
    hour: 21,
    riskScore: 72,
    level: 'high',
    topType: 'ROBBERY',
    topSeverity: 'CRITICAL',
    confidence: 'high',
    badHours: [20, 21, 22],
    safestHours: [4, 5, 6],
    nearbyTiles: [],
  );

  setUp(() {
    repository = _MockRiskRepository();
  });

  group('RiskBloc', () {
    blocTest<RiskBloc, RiskState>(
      'emite [RiskLoading, RiskLoaded, RiskLoaded+predicción] en el orden correcto',
      setUp: () {
        when(() => repository.getRisk(lat: any(named: 'lat'), lng: any(named: 'lng'), hour: any(named: 'hour')))
            .thenAnswer((_) async => riskInfo);
        when(() => repository.getPrediction(
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
              hour: any(named: 'hour'),
              dayOfWeek: any(named: 'dayOfWeek'),
            )).thenAnswer((invocation) async => _prediction(
              dayOfWeek: invocation.namedArguments[#dayOfWeek] as int,
              score: 88,
            ));
      },
      build: () => RiskBloc(repository),
      act: (bloc) => bloc.add(const RiskRequested(lat: -12.05, lng: -77.03)),
      expect: () => [
        const RiskLoading(),
        // 1er RiskLoaded: solo el riesgo determinístico (sin predicción aún)
        isA<RiskLoaded>()
            .having((s) => s.info, 'info', riskInfo)
            .having((s) => s.todayPrediction, 'todayPrediction', isNull),
        // 2do RiskLoaded: con las predicciones ML de hoy y mañana
        isA<RiskLoaded>()
            .having((s) => s.todayPrediction?.riskScore, 'today score', 88)
            .having((s) => s.tomorrowPrediction?.riskScore, 'tomorrow score', 88),
      ],
    );

    blocTest<RiskBloc, RiskState>(
      'la predicción es FAIL-OPEN: si el ML no está, igual emite RiskLoaded con available=false',
      setUp: () {
        when(() => repository.getRisk(lat: any(named: 'lat'), lng: any(named: 'lng'), hour: any(named: 'hour')))
            .thenAnswer((_) async => riskInfo);
        when(() => repository.getPrediction(
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
              hour: any(named: 'hour'),
              dayOfWeek: any(named: 'dayOfWeek'),
            )).thenAnswer((invocation) async =>
            _prediction(dayOfWeek: invocation.namedArguments[#dayOfWeek] as int));
      },
      build: () => RiskBloc(repository),
      act: (bloc) => bloc.add(const RiskRequested(lat: -12.05, lng: -77.03)),
      expect: () => [
        const RiskLoading(),
        isA<RiskLoaded>(),
        isA<RiskLoaded>().having((s) => s.todayPrediction?.available, 'available', false),
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
