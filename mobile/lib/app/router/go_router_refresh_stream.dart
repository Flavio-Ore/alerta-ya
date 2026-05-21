import 'dart:async';

import 'package:flutter/material.dart';

/// Adapta un Stream a ChangeNotifier para que GoRouter re-evalúe redirect
/// cada vez que el stream emita un nuevo valor.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
