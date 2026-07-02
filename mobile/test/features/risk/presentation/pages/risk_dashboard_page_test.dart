import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/services/photon_service.dart';
import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/repositories/risk_repository.dart';
import 'package:alertaya/features/risk/presentation/bloc/risk_bloc.dart';
import 'package:alertaya/features/risk/presentation/pages/risk_address_search.dart';
import 'package:alertaya/features/risk/presentation/pages/risk_dashboard_page.dart';

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
    when(() => repository.getRisk(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          hour: any(named: 'hour'),
        )).thenAnswer((_) async => riskInfo);
    getIt.registerLazySingleton<RiskBloc>(() => RiskBloc(repository));
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
      'seleccionar una sugerencia de dirección dispara RiskRequested con sus coords',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RiskDashboardPage()));
    await tester.pump();

    // Simula la selección de una sugerencia Photon a través del callback
    // público que el dashboard le pasa a RiskAddressSearch.
    final searchWidget = tester.widget<RiskAddressSearch>(
      find.byType(RiskAddressSearch),
    );
    const suggestion = PhotonSuggestion(
      displayName: 'Av. Larco, Miraflores',
      lat: -12.121,
      lng: -77.029,
    );
    searchWidget.onAddressSelected(suggestion);
    await tester.pump();

    verify(() => repository.getRisk(
          lat: -12.121,
          lng: -77.029,
          hour: any(named: 'hour'),
        )).called(1);
  });
}
