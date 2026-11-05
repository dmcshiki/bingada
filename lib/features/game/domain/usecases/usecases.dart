import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

/// Thin orchestration over repositories + pure services (Clean Architecture).

final class CreateGameInput {
  const CreateGameInput({
    required this.eventName,
    required this.access,
    required this.template,
    required this.prizes,
    required this.endOfGamePrizes,
    required this.prizePolicy,
    required this.settings,
  });

  final String eventName;
  final AccessPolicy access;
  final CardTemplate template;
  final List<Prize> prizes;
  final List<Prize> endOfGamePrizes;
  final PrizePolicy prizePolicy;
  final GameSettings settings;
}

final class CreateGame {
  const CreateGame(this._repo, this._secrets, this._seq, this._join);

  final GameRepository _repo;
  final HostSecretStore _secrets;
  final DrawSequence _seq;
  final JoinGame _join;

  Future<Game> call(AppUser host, CreateGameInput input) async {
    final drawSeed = _seq.newSecretHex();
    final draft = Game(
      id: const GameId(''),
      roomCode: const RoomCode(''),
      hostUid: host.uid,
      eventName: input.eventName,
      access: input.access,
      template: input.template,
      prizes: input.prizes,
      endOfGamePrizes: input.endOfGamePrizes,
      prizePolicy: input.prizePolicy,
      settings: input.settings,
      salt: _seq.newSecretHex(),
      drawCommit: _seq.commitOf(drawSeed),
      createdAt: DateTime.now().toUtc(),
    );
    final game = await _repo.createGame(draft);
    await _secrets.saveDrawSeed(game.id, drawSeed);
    if (input.settings.hostPlays) await _join(game, host);
    return game;
  }
}

final class JoinGame {
  const JoinGame(this._repo, this._generator);

  final GameRepository _repo;
  final CardGenerator _generator;

  /// Returns the (existing or new) card of [user].
  Future<BingoCard> call(Game game, AppUser user) async {
    final existing = await _repo.getCard(game.id, user.uid);
    if (existing != null) return existing;
    if (game.status == GameStatus.running) {
      throw const GameFailure(GameFailureCode.alreadyStarted);
    }
    if (game.status != GameStatus.lobby) {
      throw const GameFailure(GameFailureCode.finished);
    }
    if (game.playerCount >= game.maxPlayers) {
      throw const GameFailure(GameFailureCode.roomFull);
    }
    final card = _generator.generate(
      uid: user.uid,
      gameId: game.id,
      salt: game.salt,
      template: game.template,
    );
    await _repo.join(
      game.id,
      player: Player(
        uid: user.uid,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        joinedAt: DateTime.now().toUtc(),
      ),
      email: user.email,
      card: card,
    );
    return card;
  }
}

final class StartGame {
  const StartGame(this._repo, this._seq);

  final GameRepository _repo;
  final DrawSequence _seq;

  Future<void> call(Game game) async {
    final cards = await _repo.getCards(game.id);
    await _repo.start(game.id, cardsHash: _seq.cardsHash(cards));
  }
}

final class DrawNext {
  const DrawNext(this._repo, this._secrets, this._seq);

  final GameRepository _repo;
  final HostSecretStore _secrets;
  final DrawSequence _seq;

  /// Appends the next ball of the committed sequence.
  Future<ItemId> call(Game game) async {
    final seed = await _secrets.loadDrawSeed(game.id);
    if (seed == null || game.cardsHash == null) {
      throw const GameFailure(
        GameFailureCode.notHost,
        'Seed do sorteio ausente neste dispositivo.',
      );
    }
    final finalSeed = _seq.finalSeed(
      drawSeedHex: seed,
      cardsHash: game.cardsHash!,
    );
    final seq = _seq.sequence(finalSeedHex: finalSeed, template: game.template);
    if (game.draws.length >= seq.length) {
      throw const GameFailure(GameFailureCode.finished);
    }
    final next = seq[game.draws.length];
    await _repo.appendDraw(game.id, next);
    return next;
  }
}

final class CallBingo {
  const CallBingo(this._repo);

  final GameRepository _repo;

  Future<ClaimId> call(Game game, UserId uid, Set<int> marked) {
    final open = game.openPrizes;
    if (open.isEmpty) throw const GameFailure(GameFailureCode.finished);
    // Several prizes may be open at once: claim the one the marks complete.
    final t = game.template;
    final filled = {...marked, ?t.freeCellIndex};
    final prize = open.firstWhere(
      (p) => const PatternDetector()
          .completed(filled: filled, rows: t.rows, cols: t.cols, prize: p)
          .isNotEmpty,
      orElse: () => open.first,
    );
    return _repo.createClaim(
      game.id,
      Claim(
        id: const ClaimId(''),
        uid: uid,
        prizeId: prize.id,
        drawIndex: game.draws.length,
        markedCells: marked.toList()..sort(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}

final class VerifyClaim {
  const VerifyClaim(this._repo, this._verifier, this._generator);

  final GameRepository _repo;
  final BingoVerifier _verifier;
  final CardGenerator _generator;

  Future<ClaimResult> call(Game game, Claim claim, List<Claim> history) async {
    final card = await _repo.getCard(game.id, claim.uid);
    if (card == null) {
      return const ClaimResult(
        verdict: ClaimVerdict.tampered,
        reason: 'Cartela não encontrada.',
      );
    }
    final expected = _generator.generate(
      uid: claim.uid,
      gameId: game.id,
      salt: game.salt,
      template: game.template,
    );
    return _verifier.verify(
      game: game,
      claim: claim,
      card: card,
      expectedCard: expected,
      history: history,
    );
  }
}

/// Confirms or rejects one claim, persisting the verdict.
final class ResolveClaim {
  const ResolveClaim(this._repo);

  final GameRepository _repo;

  Future<void> call(
    Game game,
    Claim claim,
    ClaimResult result, {
    required bool accept,
  }) => _repo.updateClaim(
    game.id,
    claim.copyWith(
      verdict: result.verdict,
      matched: result.matched,
      status: accept ? ClaimStatus.confirmed : ClaimStatus.rejected,
    ),
  );
}

final class ResolveTie {
  const ResolveTie(this._secrets, this._seq, this._tie);

  final HostSecretStore _secrets;
  final DrawSequence _seq;
  final TieBreaker _tie;

  Future<UserId> call(Game game, List<UserId> tied, {PrizeId? prizeId}) async {
    final seed = await _secrets.loadDrawSeed(game.id);
    if (seed == null || game.cardsHash == null) {
      throw const GameFailure(GameFailureCode.notHost);
    }
    final finalSeed = _seq.finalSeed(
      drawSeedHex: seed,
      cardsHash: game.cardsHash!,
    );
    return _tie.pick(
      finalSeedHex: finalSeed,
      prizeId: prizeId ?? game.currentPrize!.id,
      tied: tied,
    );
  }
}

/// Records prize winners; ends the game when it was the last sequential prize.
final class ConfirmPrize {
  const ConfirmPrize(this._repo, this._end);

  final GameRepository _repo;
  final EndGame _end;

  Future<void> call(Game game, List<Winner> winners) async {
    await _repo.confirmPrize(game.id, winners: winners);
    final updated = await _repo.getGame(game.id) ?? game;
    if (updated.openPrizes.isEmpty) await _end(updated);
  }
}

final class EndGame {
  const EndGame(
    this._repo,
    this._secrets,
    this._seq,
    this._underdog,
    this._tie,
  );

  final GameRepository _repo;
  final HostSecretStore _secrets;
  final DrawSequence _seq;
  final UnderdogCalculator _underdog;
  final TieBreaker _tie;

  Future<void> call(
    Game game, {
    GameStatus status = GameStatus.finished,
  }) async {
    final seed = await _secrets.loadDrawSeed(game.id);
    if (seed == null) throw const GameFailure(GameFailureCode.notHost);
    final cards = await _repo.getCards(game.id);
    final finalSeed = _seq.finalSeed(
      drawSeedHex: seed,
      cardsHash: game.cardsHash ?? _seq.cardsHash(cards),
    );
    // Azarão still open at the end: whoever is left standing ties (R26).
    final endWinners = underdogWinners(
      game: game,
      cards: cards,
      finalSeedHex: finalSeed,
      gameOver: true,
      calculator: _underdog,
      tieBreaker: _tie,
    );
    await _repo.finish(
      game.id,
      status: status,
      drawSeed: seed,
      endOfGameWinners: endWinners,
    );
  }
}

/// Winners of every azarão prize that is not awarded yet and is decided by
/// the draws so far (see [UnderdogCalculator]). Ties follow
/// `settings.underdogTie`: a seeded draw picks one, or all of them win.
List<Winner> underdogWinners({
  required Game game,
  required List<BingoCard> cards,
  required String finalSeedHex,
  required bool gameOver,
  required UnderdogCalculator calculator,
  required TieBreaker tieBreaker,
}) {
  final awarded = {for (final w in game.winners) w.prizeId};
  final out = <Winner>[];
  for (final prize in game.endOfGamePrizes) {
    if (prize.pattern != PatternKind.underdog) continue;
    if (awarded.contains(prize.id)) continue;
    final r = calculator.run(
      cards: cards,
      draws: game.draws,
      underdogPrize: prize,
      winners: game.winners,
      policy: game.prizePolicy,
      freeCellIndex: game.template.freeCellIndex,
      gameOver: gameOver,
    );
    if (!r.decided || r.survivors.isEmpty) continue;
    final picked = r.tied && game.settings.underdogTie == TieBreakRule.draw
        ? [
            tieBreaker.pick(
              finalSeedHex: finalSeedHex,
              prizeId: prize.id,
              tied: r.survivors,
            ),
          ]
        : r.survivors;
    out.addAll([
      for (final u in picked)
        Winner(
          prizeId: prize.id,
          uid: u,
          drawIndex: r.decidedAt ?? game.draws.length,
          tieBreak: r.tied,
        ),
    ]);
  }
  return out;
}

/// Host side, after each ball: awards the azarão as soon as one player is
/// left. Only runs when the game has an azarão prize, and reads the cards
/// once per game (they are frozen after start), so it costs one write when
/// the winner is decided and nothing otherwise.
final class AwardUnderdog {
  AwardUnderdog(
    this._repo,
    this._secrets,
    this._seq,
    this._underdog,
    this._tie,
  );

  final GameRepository _repo;
  final HostSecretStore _secrets;
  final DrawSequence _seq;
  final UnderdogCalculator _underdog;
  final TieBreaker _tie;

  final Map<GameId, List<BingoCard>> _cards = {};

  static bool hasPending(Game game) {
    final awarded = {for (final w in game.winners) w.prizeId};
    return game.status == GameStatus.running &&
        game.draws.isNotEmpty &&
        // A tie of the azarão already waits for the host's draw.
        game.raffle == null &&
        game.endOfGamePrizes.any(
          (p) => p.pattern == PatternKind.underdog && !awarded.contains(p.id),
        );
  }

  /// Returns the winners written (empty when still undecided).
  Future<List<Winner>> call(Game game) async {
    if (!hasPending(game)) return const [];
    final seed = await _secrets.loadDrawSeed(game.id);
    if (seed == null) return const [];
    final cards = _cards[game.id] ??= await _repo.getCards(game.id);
    // Real tie (the last ones fell on the same ball) with "draw": the host
    // draws it on screen instead of it being picked silently.
    if (game.settings.underdogTie == TieBreakRule.draw) {
      for (final prize in game.endOfGamePrizes) {
        if (prize.pattern != PatternKind.underdog || game.isWon(prize.id)) {
          continue;
        }
        final r = _underdog.run(
          cards: cards,
          draws: game.draws,
          underdogPrize: prize,
          winners: game.winners,
          policy: game.prizePolicy,
          freeCellIndex: game.template.freeCellIndex,
        );
        if (r.decided && r.tied) {
          await _repo.setRaffle(
            game.id,
            Raffle(
              prizeId: prize.id,
              candidates: r.survivors,
              kind: RaffleKind.underdogTie,
            ),
          );
          return const [];
        }
      }
    }
    final winners = underdogWinners(
      game: game,
      cards: cards,
      finalSeedHex: _seq.finalSeed(
        drawSeedHex: seed,
        cardsHash: game.cardsHash ?? _seq.cardsHash(cards),
      ),
      gameOver: false,
      calculator: _underdog,
      tieBreaker: _tie,
    );
    if (winners.isNotEmpty) await _repo.awardPrize(game.id, winners: winners);
    return winners;
  }
}
