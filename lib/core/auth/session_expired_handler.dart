import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionExpiredHandler {
  void Function()? onExpired;

  void notify() => onExpired?.call();
}

final sessionExpiredHandlerProvider = Provider<SessionExpiredHandler>((ref) {
  return SessionExpiredHandler();
});
