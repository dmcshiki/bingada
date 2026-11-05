import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';

part 'game.freezed.dart';

enum GameStatus { lobby, running, finished, abandoned }

enum TieBreakRule { draw, allWin }

/// Who may join (§2, R4).
@freezed
sealed class AccessPolicy with _$AccessPolicy {
  const factory AccessPolicy.domain({required List<String> domains}) =
      DomainAccess;
  const factory AccessPolicy.sameAsHost({required String hostDomain}) =
      SameAsHostAccess;
  const factory AccessPolicy.allowlist({required List<String> emails}) =
      AllowlistAccess;
  const factory AccessPolicy.public() = PublicAccess;
}

/// Extensible penalty for wrong claims (R31, §5.4). Today only [NoPenalty].
@freezed
sealed class ClaimPenaltyPolicy with _$ClaimPenaltyPolicy {
  const factory ClaimPenaltyPolicy.none() = NoPenalty;

  /// Reserved for the future: cannot claim for [draws] balls.
  const factory ClaimPenaltyPolicy.skipDraws({required int draws}) = SkipDraws;
}

@freezed
abstract class GameSettings with _$GameSettings {
  const factory GameSettings({
    @Default(true) bool hostPlays,
    @Default(true) bool showFailsOnStream,
    @Default(TieBreakRule.draw) TieBreakRule tieBreak,

    /// Tie-break of the underdog prize. Null (old games) = same as [tieBreak].
    TieBreakRule? underdogTieBreak,
    @Default(ClaimPenaltyPolicy.none()) ClaimPenaltyPolicy claimPenalty,
  }) = _GameSettings;
}

extension GameSettingsX on GameSettings {
  /// Effective underdog tie-break (falls back to [GameSettings.tieBreak]).
  TieBreakRule get underdogTie => underdogTieBreak ?? tieBreak;
}

@freezed
abstract class Winner with _$Winner {
  const factory Winner({
    required PrizeId prizeId,
    required UserId uid,
    required int drawIndex,
    @Default(false) bool tieBreak,
  }) = _Winner;
}

@freezed
abstract class Game with _$Game {
  const Game._();

  const factory Game({
    required GameId id,
    required RoomCode roomCode,
    required UserId hostUid,
    required String eventName,
    @Default(GameStatus.lobby) GameStatus status,
    required AccessPolicy access,
    required CardTemplate template,
    required List<Prize> prizes,
    @Default(<Prize>[]) List<Prize> endOfGamePrizes,
    @Default(PrizePolicy()) PrizePolicy prizePolicy,
    @Default(GameSettings()) GameSettings settings,

    /// Public, created when the game opens (hex).
    required String salt,

    /// sha256(drawSeed) published at creation (hex).
    required String drawCommit,

    /// sha256 of the ordered list of cards, published at start (hex).
    String? cardsHash,

    /// Revealed only when finished/abandoned (hex).
    String? drawSeed,
    @Default(0) int playerCount,
    @Default(60) int maxPlayers,
    @Default(0) int currentPrizeIndex,
    @Default(<ItemId>[]) List<ItemId> draws,
    @Default(<Winner>[]) List<Winner> winners,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? endedAt,

    /// Last host/player action (draw, claim, confirmation). Drives the
    /// automatic end after [idleLimit] without activity.
    DateTime? lastActivityAt,
  }) = _Game;

  /// A lobby/running game with no activity for this long ends as abandoned.
  static const idleLimit = Duration(hours: 1);

  /// Last activity, falling back to start/creation for old games.
  DateTime get lastActivity => lastActivityAt ?? startedAt ?? createdAt;

  /// When the game may be auto-abandoned (null once it is over).
  DateTime? get idleDeadline =>
      status == GameStatus.lobby || status == GameStatus.running
      ? lastActivity.add(idleLimit)
      : null;

  bool isWon(PrizeId id) => winners.any((w) => w.prizeId == id);

  /// Prizes that can be won right now. Every pattern prize except "cartela
  /// cheia" is open at the same time (e.g. Horizontal and Vertical); the full
  /// card opens only after all of them are out.
  List<Prize> get openPrizes {
    final left = [
      for (final p in prizes)
        if (!isWon(p.id)) p,
    ];
    final early = [
      for (final p in left)
        if (p.pattern != PatternKind.full) p,
    ];
    return early.isNotEmpty ? early : left;
  }

  /// First open prize (kept for single-prize copy).
  Prize? get currentPrize => openPrizes.firstOrNull;

  /// Display order: azarão first, pattern prizes, full card last.
  List<Prize> get displayPrizes => [
    ...endOfGamePrizes,
    for (final p in prizes)
      if (p.pattern != PatternKind.full) p,
    for (final p in prizes)
      if (p.pattern == PatternKind.full) p,
  ];

  Prize? prizeById(PrizeId id) {
    for (final p in [...prizes, ...endOfGamePrizes]) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Winner> winnersOf(PrizeId id) => [
    for (final w in winners)
      if (w.prizeId == id) w,
  ];

  ItemId? get currentBall => draws.isEmpty ? null : draws.last;

  bool get isOpenForJoin =>
      status == GameStatus.lobby && playerCount < maxPlayers;
}
