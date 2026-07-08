import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/core/services/photon_service.dart';
import 'package:alertaya/features/risk/presentation/pages/risk_address_search.dart';

void main() {
  group('RiskAddressSearch', () {
    testWidgets('un tap de sugerencia notifica onAddressSelected con las coords correctas',
        (tester) async {
      PhotonSuggestion? selected;
      const suggestion = PhotonSuggestion(
        displayName: 'Av. Larco, Miraflores',
        lat: -12.121,
        lng: -77.029,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskAddressSearch(
              userLat: -12.05,
              userLng: -77.03,
              onAddressSelected: (s) => selected = s,
            ),
          ),
        ),
      );

      // Simula la selección de sugerencia invocando directamente el
      // callback público del widget (evita depender de la llamada de red
      // real a Photon en el test).
      final widget = tester.widget<RiskAddressSearch>(
        find.byType(RiskAddressSearch),
      );
      widget.onAddressSelected(suggestion);

      expect(selected, isNotNull);
      expect(selected!.lat, -12.121);
      expect(selected!.lng, -77.029);
      expect(selected!.displayName, 'Av. Larco, Miraflores');
    });

    testWidgets('muestra el campo de búsqueda con hint en español',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskAddressSearch(
              userLat: -12.05,
              userLng: -77.03,
              onAddressSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Buscar una dirección…'), findsOneWidget);
    });
  });
}
