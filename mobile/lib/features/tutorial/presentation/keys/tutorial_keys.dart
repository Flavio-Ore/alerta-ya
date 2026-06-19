import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Registro centralizado de GlobalKeys para los 5 targets del tutorial.
///
/// Inyectado por DI como singleton para que tanto AppShell como MapPage
/// puedan adjudicar sus respectivos widgets sin acoplarse entre sí.
@lazySingleton
class TutorialKeys {
  final search    = GlobalKey(debugLabel: 'tutorial_search');
  final reportFab = GlobalKey(debugLabel: 'tutorial_report_fab');
  final alerts    = GlobalKey(debugLabel: 'tutorial_alerts');
  final risk      = GlobalKey(debugLabel: 'tutorial_risk');
  final panic     = GlobalKey(debugLabel: 'tutorial_panic');
}
