import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/room_gate.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/features/audit/presentation/audit_page.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/auth/presentation/login_page.dart';
import 'package:tokingo/features/errors/presentation/error_page.dart';
import 'package:tokingo/features/game/presentation/player_game_page.dart';
import 'package:tokingo/features/result/presentation/result_page.dart';
import 'package:tokingo/features/room/presentation/create/create_room_page.dart';
import 'package:tokingo/features/room/presentation/lobby_page.dart';
import 'package:tokingo/features/stream/presentation/stream_page.dart';

/// Routes reachable without signing in (spectators and auditors).
bool _isPublic(String path) =>
    path == AppRoutes.login ||
    path.startsWith('/verify/') ||
    path.startsWith('/error/') ||
    RegExp(r'^/s/[^/]+/(stream|result)$').hasMatch(path);

/// Bridges the auth stream to go_router refreshes.
final class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AppUser?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AppUser?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

RoomCode _code(GoRouterState s) => RoomCode.parse(s.pathParameters['code']!);

/// Sets the browser tab title: "Tokingo | <where>".
Widget _titled(String where, Widget page) =>
    Title(title: 'Tokingo | $where', color: AppColors.navy, child: page);

String _sala(GoRouterState s) => 'sala ${_code(s).value}';

GoRouter buildRouter() {
  final auth = sl<AuthRepository>();
  return GoRouter(
    refreshListenable: _AuthRefresh(auth.authStateChanges()),
    redirect: (context, state) {
      final path = state.uri.path;
      final signedIn = auth.currentUser != null;
      if (!signedIn && !_isPublic(path)) {
        final code = RegExp('^/s/([^/]+)').firstMatch(path)?.group(1);
        return Uri(
          path: AppRoutes.login,
          queryParameters: {'next': state.uri.toString(), 'code': ?code},
        ).toString();
      }
      if (signedIn && path == AppRoutes.login) {
        return state.uri.queryParameters['next'] ?? AppRoutes.lobby;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, s) {
          final code = s.uri.queryParameters['code'];
          return _titled(
            'Entrar',
            LoginPage(
              next: s.uri.queryParameters['next'],
              code: code == null ? null : RoomCode.parse(code),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lobby,
        builder: (_, _) => _titled('Início', const LobbyPage()),
      ),
      GoRoute(
        path: AppRoutes.create,
        builder: (_, s) {
          final from = s.uri.queryParameters['from'];
          return _titled(
            'Criar sala',
            CreateRoomPage(fromGameId: from == null ? null : GameId(from)),
          );
        },
      ),
      // Sibling routes, not children of /s/:code: a child route also builds
      // its parent, and PlayerRoomGate would redirect the host to /host.
      GoRoute(
        path: '/s/:code',
        builder: (_, s) =>
            _titled('Sala ${_code(s).value}', PlayerRoomGate(code: _code(s))),
      ),
      GoRoute(
        path: '/s/:code/play',
        builder: (_, s) =>
            _titled('Cartela · ${_sala(s)}', PlayerGamePage(code: _code(s))),
      ),
      GoRoute(
        path: '/s/:code/host',
        builder: (_, s) =>
            _titled('Host · ${_sala(s)}', HostRoomGate(code: _code(s))),
      ),
      GoRoute(
        path: '/s/:code/stream',
        builder: (_, s) => _titled(
          'Telão · ${_sala(s)}',
          StreamPage(
            code: _code(s),
            chroma: s.uri.queryParameters['chroma'] == '1',
            compact: s.uri.queryParameters['compact'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/s/:code/result',
        builder: (_, s) =>
            _titled('Resultado · ${_sala(s)}', ResultPage(code: _code(s))),
      ),
      GoRoute(
        path: '/verify/:id',
        builder: (_, s) => _titled(
          'Auditoria',
          AuditPage(gameId: GameId(s.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/error/:kind',
        builder: (_, s) {
          final code = s.uri.queryParameters['code'];
          return _titled(
            'Erro',
            ErrorPage(
              kind: s.pathParameters['kind']!,
              code: code == null ? null : RoomCode.parse(code),
            ),
          );
        },
      ),
    ],
    errorBuilder: (_, _) =>
        _titled('Erro', const ErrorPage(kind: ErrorKinds.invalidCode)),
  );
}
