import 'package:tokingo/core/types/ids.dart';

/// Route paths (§3). The router itself lives in `app_router.dart`.
abstract final class AppRoutes {
  static const login = '/login';
  static const lobby = '/';
  static const create = '/create';

  /// Create wizard pre-filled with a previous game ("Novo jogo").
  static String createFrom(GameId id) => '/create?from=${id.value}';
  static String room(RoomCode code) => '/s/${code.value}';
  static String play(RoomCode code) => '/s/${code.value}/play';
  static String host(RoomCode code) => '/s/${code.value}/host';
  static String stream(RoomCode code) => '/s/${code.value}/stream';
  static String result(RoomCode code) => '/s/${code.value}/result';
  static String verify(GameId id) => '/verify/${id.value}';

  /// Error screens (15–15e): `/error/<kind>?code=K7QP`.
  static String error(String kind, {RoomCode? code}) =>
      '/error/$kind${code == null ? '' : '?code=${code.value}'}';
}

/// Error kinds for [AppRoutes.error].
abstract final class ErrorKinds {
  static const accessDenied = 'access';
  static const roomFull = 'full';
  static const started = 'started';
  static const ended = 'ended';
  static const invalidCode = 'invalid';
}
