// maxPerPlayer = 1 chain: each player ends holding at most one prize, a
// released prize is raffled (tied players first, else every participant,
// holders included) and the chain terminates without losing prizes.
import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/services.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/host/host_panel_controller.dart';

import 'game_fakes.dart';

const _a = UserId('a'), _b = UserId('b'), _c = UserId('c');
const _hor = PrizeId('p1'), _ver = PrizeId('p2'), _full = PrizeId('p3');
const _und = PrizeId('pu');

/// Repo that actually stores winners, claims and raffles.
class _StatefulRepo extends FakeRepo {
  _StatefulRepo(super.g, this.uids);

  final List<UserId> uids;
  int finishCalls = 0;

  void _emitGame() => games.add(game);

  @override
  Stream<List<Player>> watchPlayers(GameId id) => Stream.value([
    for (final u in uids)
      Player(uid: u, displayName: u.value, joinedAt: DateTime.utc(2026)),
  ]);

  @override
  Future<void> updateClaim(GameId id, Claim claim) async {
    updated.add(claim);
    emitClaims([for (final c in claims) c.id == claim.id ? claim : c]);
  }

  @override
  Future<void> chooseClaim(
    GameId id,
    ClaimId claimId,
    ClaimChoice? choice, {
    PrizeId? releasePrizeId,
  }) async {
    emitClaims([
      for (final c in claims)
        c.id == claimId
            ? c.copyWith(choice: choice, releasePrizeId: releasePrizeId)
            : c,
    ]);
  }

  @override
  Future<void> confirmPrize(GameId id, {required List<Winner> winners}) async {
    game = game.copyWith(winners: [...game.winners, ...winners]);
    _emitGame();
  }

  @override
  Future<void> awardPrize(GameId id, {required List<Winner> winners}) async {
    game = game.copyWith(winners: [...game.winners, ...winners]);
    _emitGame();
  }

  @override
  Future<void> setWinners(GameId id, List<Winner> winners) async {
    game = game.copyWith(winners: winners);
    _emitGame();
  }

  @override
  Future<void> setRaffle(GameId id, Raffle? raffle) async {
    game = game.copyWith(raffle: raffle);
    _emitGame();
  }

  @override
  Future<void> finish(
    GameId id, {
    required GameStatus status,
    required String drawSeed,
    required List<Winner> endOfGameWinners,
  }) async {
    finishCalls++;
    game = game.copyWith(
      status: status,
      winners: [...game.winners, ...endOfGameWinners],
    );
    _emitGame();
  }
}

Game _game(List<Winner> winners) => runningGame(winners: winners).copyWith(
  prizes: const [
    Prize(id: _hor, label: 'H', pattern: PatternKind.horizontal, order: 1),
    Prize(id: _ver, label: 'V', pattern: PatternKind.vertical, order: 2),
    Prize(id: _full, label: 'Cheia', pattern: PatternKind.full, order: 3),
  ],
  endOfGamePrizes: const [
    Prize(id: _und, label: 'Azarão', pattern: PatternKind.underdog),
  ],
  prizePolicy: const PrizePolicy(),
  settings: const GameSettings(overLimit: OverLimitRule.raffle),
);

Claim _fullClaim(UserId uid) => Claim(
  id: const ClaimId('full-a'),
  uid: uid,
  prizeId: _full,
  drawIndex: 23,
  createdAt: DateTime.utc(2026),
);

Future<(HostPanelController, _StatefulRepo)> _setup(
  List<Winner> winners,
  List<UserId> uids,
) async {
  final repo = _StatefulRepo(_game(winners), uids)..claims = [_fullClaim(_a)];
  final secrets = FakeSecrets();
  const seq = DrawSequence();
  final end = EndGame(
    repo,
    secrets,
    seq,
    const UnderdogCalculator(),
    const TieBreaker(),
  );
  final h = HostPanelController(
    code: const RoomCode('K7QP'),
    repository: repo,
    trackUnderdog: false,
    drawNext: DrawNext(repo, secrets, seq),
    verifyClaim: VerifyClaim(
      repo,
      const BingoVerifier(),
      const CardGenerator(),
    ),
    resolveClaim: ResolveClaim(repo),
    resolveTie: ResolveTie(secrets, seq, const TieBreaker()),
    confirmPrize: ConfirmPrize(repo, end),
    endGame: end,
  );
  // Card contents are irrelevant: the BINGO is taken as valid.
  h.results[const ClaimId('full-a')] = const ClaimResult(
    verdict: ClaimVerdict.valid,
  );
  await h.start();
  await pumpEventQueue(times: 50);
  return (h, repo);
}

Winner _w(PrizeId p, UserId u) => Winner(prizeId: p, uid: u, drawIndex: 10);

Map<UserId, List<PrizeId>> _holdings(Game g) {
  final out = <UserId, List<PrizeId>>{};
  for (final w in g.winners) {
    (out[w.uid] ??= []).add(w.prizeId);
  }
  return out;
}

void _expectInvariant(Game g) {
  for (final e in _holdings(g).entries) {
    expect(
      e.value.length,
      lessThanOrEqualTo(1),
      reason: '${e.key.value} holds ${e.value}',
    );
  }
  final ids = [for (final w in g.winners) w.prizeId];
  expect(ids.toSet().length, ids.length, reason: 'duplicated prize: $ids');
}

/// Runs the chain: answers each choice with [answer], runs each raffle.
/// Returns the list of events (for the report) or fails on a hang.
Future<List<String>> _drive(
  HostPanelController h,
  _StatefulRepo repo,
  PrizeId Function(Claim c, Game g) answer, {
  int maxSteps = 30,
}) async {
  final log = <String>[];
  for (var i = 0; i < maxSteps; i++) {
    await pumpEventQueue(times: 50);
    final g = repo.game;
    final waiting = repo.claims.where(
      (c) => c.status == ClaimStatus.awaitingChoice && !c.answered,
    );
    if (waiting.isNotEmpty) {
      final c = waiting.first;
      final rel = answer(c, g);
      log.add('${c.uid.value} releases ${rel.value}');
      await repo.chooseClaim(g.id, c.id, null, releasePrizeId: rel);
      continue;
    }
    if (g.raffle case final r? when r.winner == null) {
      final ok = await h.runRaffle();
      await pumpEventQueue(times: 50);
      log.add(
        'raffle ${r.prizeId.value} among '
        '${r.candidates.map((u) => u.value).toList()} -> '
        '${repo.game.raffle?.winner?.value} (ok=$ok)',
      );
      continue;
    }
    return log;
  }
  fail('chain did not terminate: $log');
}

void main() {
  _forgedRelease();
  _verifierGaveUp();
  test(
    '(a) A keeps Cartela cheia; Vertical raffled; each holds <= 1',
    () async {
      final (h, repo) = await _setup([_w(_ver, _a)], [_a, _b, _c]);
      expect(await h.confirmSingle(_fullClaim(_a)), isTrue);
      await pumpEventQueue(times: 50);
      expect(repo.claims.single.status, ClaimStatus.awaitingChoice);
      final log = await _drive(h, repo, (c, g) => _ver);
      final g = repo.game;
      _expectInvariant(g);
      expect(_holdings(g)[_a], [_full], reason: '$log');
      expect(g.winnersOf(_ver), hasLength(1), reason: 'Vertical lost: $log');
    },
  );

  test('(b) chain A->B->C swaps terminates and keeps the invariant', () async {
    final (h, repo) = await _setup(
      [_w(_ver, _a), _w(_und, _b), _w(_hor, _c)],
      [_a, _b, _c],
    );
    await h.confirmSingle(_fullClaim(_a));
    // A keeps the new prize; any holder winning a raffle swaps.
    final log = await _drive(h, repo, (c, g) {
      if (c.uid == _a && c.id == const ClaimId('full-a')) return _ver;
      final held = _policyHeld(c.uid, g, except: c.offerPrizeId ?? c.prizeId);
      return held.first;
    });
    final g = repo.game;
    _expectInvariant(g);
    // Everyone keeps swapping, so a prize may end unassigned once every
    // other player gave it up: then it is back in play, never lost.
    for (final p in [_hor, _ver, _full]) {
      if (g.winnersOf(p).isEmpty) {
        expect(g.openPrizes.map((o) => o.id), contains(p), reason: "$log");
      }
    }
    expect(g.winners.length, greaterThanOrEqualTo(3), reason: "$log");
  });

  test(
    '(c) only holders left and all keep: released prize does not hang',
    () async {
      final (h, repo) = await _setup(
        [_w(_ver, _a), _w(_und, _b), _w(_hor, _c)],
        [_a, _b, _c],
      );
      await h.confirmSingle(_fullClaim(_a));
      final log = await _drive(h, repo, (c, g) => c.offerPrizeId ?? c.prizeId);
      final g = repo.game;
      _expectInvariant(g);
      // Rule: the raffle pool includes holders, so Vertical must have been
      // raffled among B and C at least once.
      expect(
        log.any((l) => l.startsWith('raffle p3')),
        isTrue,
        reason:
            'no raffle for released Cartela cheia; log=$log '
            'status=${g.status} open=${g.openPrizes.map((p) => p.id.value)}',
      );
      // Either assigned, or explicitly unassigned while the game can still end.
      if (g.winnersOf(_full).isEmpty) {
        expect(h.endBlockedReason, isNull, reason: 'game stuck: $log');
      }
    },
  );

  test('(d) ending the game while a choice is pending is blocked', () async {
    final (h, repo) = await _setup([_w(_ver, _a)], [_a, _b, _c]);
    await h.confirmSingle(_fullClaim(_a));
    await pumpEventQueue(times: 50);
    expect(repo.claims.single.status, ClaimStatus.awaitingChoice);
    expect(await h.endEarly(), isFalse);
    expect(repo.finishCalls, 0);
    expect(repo.game.status, GameStatus.running);
    // After answering the chain completes and the game can end.
    await _drive(h, repo, (c, g) => _ver);
    _expectInvariant(repo.game);
    expect(h.endBlockedReason == null || h.isFinished, isTrue);
  });
}

List<PrizeId> _policyHeld(UserId uid, Game g, {required PrizeId except}) => [
  for (final w in g.winners)
    if (w.uid == uid && w.prizeId != except) w.prizeId,
];

void _forgedRelease() {
  test('(e) a forged release of a prize not held keeps the old one', () async {
    final (h, repo) = await _setup([_w(_ver, _a)], [_a, _b]);
    await h.confirmSingle(_fullClaim(_a));
    final log = await _drive(h, repo, (c, g) => _hor); // A never held H
    final g = repo.game;
    _expectInvariant(g);
    expect(_holdings(g)[_a], [_ver], reason: '$log');
  });
}

void _verifierGaveUp() {
  test('(f) verifier: a prize given up earlier cannot be claimed back', () {
    final before = Claim(
      id: const ClaimId('x1'),
      uid: _a,
      prizeId: _full,
      drawIndex: 5,
      status: ClaimStatus.confirmed,
      releasePrizeId: _hor,
      createdAt: DateTime.utc(2026),
    );
    final again = Claim(
      id: const ClaimId('x2'),
      uid: _a,
      prizeId: _hor,
      drawIndex: 7,
      createdAt: DateTime.utc(2026),
    );
    final g = _game(const []);
    final card = BingoCard(
      owner: _a,
      cells: List.filled(g.template.rows * g.template.cols, null),
    );
    final r = const BingoVerifier().verify(
      game: g,
      claim: again,
      card: card,
      expectedCard: card,
      history: [before],
    );
    expect(r.verdict, ClaimVerdict.notEligible);
  });
}
