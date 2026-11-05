import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';

/// Thrown by repositories with a machine-readable [code].
final class GameFailure implements Exception {
  const GameFailure(this.code, [this.message = '']);

  final GameFailureCode code;
  final String message;

  @override
  String toString() => 'GameFailure($code, $message)';
}

enum GameFailureCode {
  roomNotFound,
  accessDenied,
  roomFull,
  alreadyStarted,
  finished,
  notHost,
  pendingClaims,
  conflict,
  unknown,
}

/// Persistence of games, players, cards and claims (§7).
abstract interface class GameRepository {
  /// Persists a new game (status lobby) and reserves a free room code.
  Future<Game> createGame(Game draft);

  Future<Game?> findByRoomCode(RoomCode code);

  Future<Game?> getGame(GameId id);

  Stream<Game> watchGame(GameId id);

  Stream<List<Player>> watchPlayers(GameId id);

  Future<BingoCard?> getCard(GameId id, UserId uid);

  Future<List<BingoCard>> getCards(GameId id);

  /// Atomic: checks access/capacity/status, creates player + card once,
  /// increments `playerCount`. Re-joining returns silently (card kept).
  Future<void> join(
    GameId id, {
    required Player player,
    required String email,
    required BingoCard card,
  });

  /// lobby → running, publishes [cardsHash].
  Future<void> start(GameId id, {required String cardsHash});

  /// Appends exactly one ball. Fails with [GameFailureCode.pendingClaims].
  Future<void> appendDraw(GameId id, ItemId item);

  Future<ClaimId> createClaim(GameId id, Claim claim);

  Stream<List<Claim>> watchClaims(GameId id);

  Future<void> updateClaim(GameId id, Claim claim);

  /// Records winners of the current prize and advances `currentPrizeIndex`.
  Future<void> confirmPrize(GameId id, {required List<Winner> winners});

  /// Appends winners of an end-of-game prize decided mid-game (azarão),
  /// without moving `currentPrizeIndex`. Ignored if that prize already has
  /// winners.
  Future<void> awardPrize(GameId id, {required List<Winner> winners});

  /// Host: replaces the whole winners list (prize swaps).
  Future<void> setWinners(GameId id, List<Winner> winners);

  /// Host: starts, decides ([Raffle.winner]) or clears an on-screen draw.
  /// The next ball clears it too.
  Future<void> setRaffle(GameId id, Raffle? raffle);

  /// Player: answers an `awaitingChoice` claim of their own. [choice] is the
  /// legacy keep/swap; [releasePrizeId] names the prize given up.
  Future<void> chooseClaim(
    GameId id,
    ClaimId claimId,
    ClaimChoice? choice, {
    PrizeId? releasePrizeId,
  });

  /// Anyone: ends a lobby/running game as `abandoned` after
  /// [Game.idleLimit] without activity (no seed reveal; the host does that).
  Future<void> abandonIdle(GameId id);

  /// finished/abandoned: reveals the seed and stores end-of-game winners.
  Future<void> finish(
    GameId id, {
    required GameStatus status,
    required String drawSeed,
    required List<Winner> endOfGameWinners,
  });
}

/// Host-only secrets kept on the host device (localStorage on web).
abstract interface class HostSecretStore {
  Future<void> saveDrawSeed(GameId id, String seedHex);

  Future<String?> loadDrawSeed(GameId id);
}

/// Player stamps are local until a claim (R13).
abstract interface class MarksStore {
  Future<Set<int>> load(GameId id, UserId uid);

  Future<void> save(GameId id, UserId uid, Set<int> marked);
}

/// Host online presence (RTDB `onDisconnect`, 09d).
abstract interface class PresenceRepository {
  Future<void> announceHost(GameId id);

  Stream<bool> watchHostOnline(GameId id);
}
