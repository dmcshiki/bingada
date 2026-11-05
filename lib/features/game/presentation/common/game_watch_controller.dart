import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';

/// Resolves a room code and keeps the game, players and claims live.
///
/// Shared read model used by the player page, host panel and stream page.
/// Each page owns its own instance (never shared between features' admin
/// and read-only UIs: the stream only reads).
class GameWatchController extends ChangeNotifier {
  GameWatchController({
    required this.code,
    required GameRepository repository,
    this._presence,
  }) : _repo = repository;

  final RoomCode code;
  final GameRepository _repo;
  final PresenceRepository? _presence;

  /// Presence backend, for subclasses that announce themselves (host).
  @protected
  PresenceRepository? get presenceRepository => _presence;

  @protected
  GameRepository get repository => _repo;

  final List<StreamSubscription<Object?>> _subs = [];
  bool _disposed = false;

  Game? game;
  List<Player> players = const [];
  List<Claim> claims = const [];
  bool hostOnline = true;
  bool loading = true;
  Object? error;

  Future<void> start() async {
    try {
      final found = await _repo.findByRoomCode(code);
      if (_disposed) return;
      if (found == null) {
        loading = false;
        error = const GameFailure(GameFailureCode.roomNotFound);
        notifyListeners();
        return;
      }
      game = found;
      loading = false;
      _scheduleIdle(found);
      notifyListeners();
      _subs
        ..add(_repo.watchGame(found.id).listen(_onGame, onError: _onError))
        ..add(
          _repo.watchPlayers(found.id).listen((p) {
            players = p;
            rememberPlayerPhotos(p);
            notifyListeners();
          }, onError: _onError),
        )
        ..add(
          _repo.watchClaims(found.id).listen((c) {
            final first = !_claimsReceived;
            _claimsReceived = true;
            claims = c;
            onClaimsChanged(c, first: first);
            notifyListeners();
          }, onError: _onError),
        );
      final presence = _presence;
      if (presence != null) {
        _subs.add(
          presence.watchHostOnline(found.id).listen((online) {
            hostOnline = online;
            notifyListeners();
          }, onError: (_) {}),
        );
      }
    } on Object catch (e) {
      if (_disposed) return;
      loading = false;
      error = e;
      notifyListeners();
    }
  }

  /// Hook for subclasses to react before listeners are notified.
  @protected
  void onGameChanged(Game? previous, Game next) {}

  bool _claimsReceived = false;

  /// Hook called on every claims emission ([first] for the initial one).
  @protected
  void onClaimsChanged(List<Claim> next, {required bool first}) {}

  void _onGame(Game g) {
    final prev = game;
    game = g;
    _scheduleIdle(g);
    onGameChanged(prev, g);
    notifyListeners();
  }

  Timer? _idleTimer;

  /// Clock of this client (overridable in tests).
  @protected
  DateTime now() => DateTime.now().toUtc();

  /// Ends the game as abandoned after [Game.idleLimit] without activity.
  /// No server runs this: every client watching (or opening) the game does,
  /// and the rules accept it only once the hour has really passed.
  void _scheduleIdle(Game g, {Duration slack = const Duration(seconds: 5)}) {
    _idleTimer?.cancel();
    _idleTimer = null;
    final deadline = g.idleDeadline;
    if (deadline == null || _disposed) return;
    var wait = deadline.toUtc().difference(now()) + slack;
    if (wait.isNegative) wait = Duration.zero;
    _idleTimer = Timer(wait, () => unawaited(_endIdle(g.id)));
  }

  Future<void> _endIdle(GameId id) async {
    if (_disposed) return;
    final g = game;
    if (g == null || g.id != id || g.idleDeadline == null) return;
    try {
      await _repo.abandonIdle(id);
    } on Object {
      // Clock skew or a race with real activity: try again in a minute.
      if (_disposed) return;
      _idleTimer = Timer(
        const Duration(minutes: 1),
        () => unawaited(_endIdle(id)),
      );
    }
  }

  void _onError(Object e) {
    error = e;
    notifyListeners();
  }

  /// Claims for the current draw window still waiting for the host (R28).
  List<Claim> get pendingClaims => [
    for (final c in claims)
      if (c.status == ClaimStatus.pending) c,
  ];

  bool get isFinished =>
      game?.status == GameStatus.finished ||
      game?.status == GameStatus.abandoned;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _idleTimer?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    super.dispose();
  }
}
