import 'package:tokingo/features/auth/data/tab_session_stub.dart'
    if (dart.library.js_interop) 'package:tokingo/features/auth/data/tab_session_web.dart'
    as impl;

/// Per-tab storage (sessionStorage on web, memory elsewhere). Used by the
/// demo auth so each browser tab can be a different player while game
/// data is shared across tabs through localStorage.
abstract final class TabSession {
  static String? read(String key) => impl.read(key);

  static void write(String key, String? value) => impl.write(key, value);
}
