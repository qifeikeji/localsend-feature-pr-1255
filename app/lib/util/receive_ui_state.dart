import 'package:common/common.dart';
import 'package:localsend_app/model/state/server/server_state.dart';

/// True when the receive tab can show the outbound send queue (no active incoming transfer).
bool isReceiveUiIdle(ServerState? serverState) {
  final session = serverState?.session;
  if (session == null) {
    return true;
  }
  return session.status != SessionStatus.waiting && session.status != SessionStatus.sending;
}
