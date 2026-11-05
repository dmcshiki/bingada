import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';

/// Resolves a room code and keeps the game + players live.
class RoomWatchController extends ChangeNotifier {
  RoomWatchController(this.code, {this.watchPlayers = false});

  final RoomCode code;
  final bool watchPlayers;

  Game? game;
  List<Player> players = const [];
  bool loading = true;
  bool notFound = false;
  Object? error;

  StreamSubscription<Game>? _gameSub;
  StreamSubscription<List<Player>>? _playersSub;
  bool _disposed = false;

  Future<void> load() async {
    try {
      final repo = sl<GameRepository>();
      final g = await repo.findByRoomCode(code);
      if (_disposed) return;
      if (g == null) {
        notFound = true;
        loading = false;
        notifyListeners();
        return;
      }
      game = g;
      loading = false;
      notifyListeners();
      _gameSub = repo.watchGame(g.id).listen((u) {
        game = u;
        notifyListeners();
      }, onError: _onError);
      if (watchPlayers) {
        _playersSub = repo.watchPlayers(g.id).listen((p) {
          players = p;
          notifyListeners();
        }, onError: _onError);
      }
    } on Object catch (e) {
      _onError(e);
    }
  }

  void _onError(Object e) {
    if (_disposed) return;
    error = e;
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_gameSub?.cancel());
    unawaited(_playersSub?.cancel());
    super.dispose();
  }
}
