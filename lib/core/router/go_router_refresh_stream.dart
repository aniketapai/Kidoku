import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a Stream (here, Firebase's auth state changes) to the
/// [Listenable] go_router's `refreshListenable` expects, so a sign-in or
/// sign-out re-evaluates the router's redirect immediately.
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
