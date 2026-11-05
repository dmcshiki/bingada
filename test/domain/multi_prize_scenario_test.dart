import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/data/local/key_value_store.dart';
import 'package:tokingo/features/game/data/local/local_game_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/services.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/host/host_panel_controller.dart';

import 'fixtures.dart';

/// Host + 4 players, 4 prizes (azarão, horizontal, vertical, full card),
/// at most 2 prizes per person. Walks the whole flow with the real host
/// controller, use cases and the in-memory repository.
void main() {
  const others = ['host', 'ana', 'bia', 'caio', 'duda'];

  test('policy: prizes open together can be held in any order', () {
    // As the room creator writes it: a row lists only later prizes.
    const policy = PrizePolicy(
      maxPerPlayer: 2,
      allow: {
        PrizeId('p1'): [PrizeId('p2'), PrizeId('u1')],
        PrizeId('p2'): [PrizeId('u1')],
      },
    );
    const e = PrizePolicyEvaluator();
    // Won Vertical (p2) first, then Horizontal (p1): allowed.
    expect(
      e.canHold([const PrizeId('p2'), const PrizeId('p1')], policy),
      isTrue,
    );
    expect(
      e.canHold([const PrizeId('u1'), const PrizeId('p1')], policy),
      isTrue,
    );
    expect(
      e.canHold([
        const PrizeId('u1'),
        const PrizeId('p1'),
        const PrizeId('p2'),
      ], policy),
      isFalse,
    );
  });

  test('azarão tie → host draw; then horizontal, then vertical tie where '
      'the winner at the limit SKIPS: the other player takes it', () async {
    final s = await _Scenario.start(others);
    final (w, y) = await s.underdogTieAndRaffle();
    await s.winHorizontal(w);
    expect(s.held(w), {const PrizeId('u1'), const PrizeId('p1')});

    final (cw, cy) = await s.verticalTie(w, y);
    final tied = s.host.tiedFor(cw);
    expect(tied.map((c) => c.uid).toSet(), {w, y});

    await s.host.askTieOptIns(tied);
    await s.settle();
    expect(s.claim(cw).status, ClaimStatus.awaitingChoice);
    expect(s.claim(cw).tieOptIn, isTrue);
    expect(s.claim(cy).status, ClaimStatus.pending);
    expect(s.host.drawBlockedReason, isNotNull);

    await s.repo.chooseClaim(s.id, cw.id, ClaimChoice.skip);
    await s.settle();
    expect(s.claim(cw).status, ClaimStatus.declined);
    final st = s.host.tieState(tied);
    expect(st.waiting, isFalse);
    expect(st.live.map((c) => c.uid), [y]);

    expect(await s.host.awardSoleTied(st.live.single), isTrue);
    await s.settle();
    expect(s.held(w), {const PrizeId('u1'), const PrizeId('p1')});
    expect(s.held(y), {const PrizeId('p2')});
    s.dispose();
  });

  test('vertical tie where the winner at the limit JOINS: both outcomes of '
      'the draw are handled', () async {
    final seen = <String>{};
    for (var i = 0; i < 12 && seen.length < 2; i++) {
      final s = await _Scenario.start(others, seed: _seed(i));
      final (w, y) = await s.underdogTieAndRaffle();
      await s.winHorizontal(w);
      final (cw, _) = await s.verticalTie(w, y);
      final tied = s.host.tiedFor(cw);
      await s.host.askTieOptIns(tied);
      await s.settle();
      await s.repo.chooseClaim(s.id, cw.id, ClaimChoice.join);
      await s.settle();
      final live = s.host.tieState(tied).live;
      expect(live.map((c) => c.uid).toSet(), {w, y});

      final winner = await s.host.drawTie(live);
      expect(await s.host.confirmTie(live, winner!), isTrue);
      await s.settle();
      if (winner == w) {
        seen.add('w');
        // Three prizes over a limit of two: W picks which to give up.
        expect(s.claim(cw).status, ClaimStatus.awaitingChoice);
        expect(s.claim(cw).tieOptIn, isFalse);
        await s.repo.chooseClaim(
          s.id,
          cw.id,
          null,
          releasePrizeId: const PrizeId('u1'),
        );
        await s.settle();
        expect(s.held(w), {const PrizeId('p1'), const PrizeId('p2')});
        // The prize given up goes to the only other one who bingoed.
        expect(s.held(y), {const PrizeId('u1')});
      } else {
        seen.add('y');
        expect(s.held(w), {const PrizeId('u1'), const PrizeId('p1')});
        expect(s.held(y), {const PrizeId('p2')});
      }
      s.dispose();
    }
    expect(seen, {'w', 'y'});
  });

  test('alone over the limit, room rule "raffle": the prize given up is '
      'drawn among everyone still under the limit', () async {
    final s = await _Scenario.start(others, overLimit: OverLimitRule.raffle);
    final (w, _) = await s.underdogTieAndRaffle();
    await s.winHorizontal(w);
    final cw = await s.winVerticalAlone(w);
    expect(s.claim(cw).status, ClaimStatus.awaitingChoice);
    await s.repo.chooseClaim(
      s.id,
      cw.id,
      null,
      releasePrizeId: const PrizeId('p1'),
    );
    await s.settle();
    expect(s.held(w), {const PrizeId('u1'), const PrizeId('p2')});
    final r = s.game.raffle!;
    expect(r.kind, RaffleKind.released);
    expect(r.prizeId, const PrizeId('p1'));
    expect(r.releasedBy, w);
    expect(r.candidates, isNot(contains(w)));
    expect(r.candidates, hasLength(4));
    expect(s.host.drawBlockedReason, contains('sorteio'));

    expect(await s.host.runRaffle(), isTrue);
    await s.settle();
    final winner = s.game.raffle!.winner!;
    expect(r.candidates, contains(winner));
    expect(s.held(winner), contains(const PrizeId('p1')));
    expect(s.host.drawBlockedReason, isNull);
    s.dispose();
  });

  test('alone over the limit, room rule "back to game": the prize given up '
      'is open again', () async {
    final s = await _Scenario.start(others);
    final (w, _) = await s.underdogTieAndRaffle();
    await s.winHorizontal(w);
    final cw = await s.winVerticalAlone(w);
    await s.repo.chooseClaim(
      s.id,
      cw.id,
      null,
      releasePrizeId: const PrizeId('p2'),
    );
    await s.settle();
    expect(s.held(w), {const PrizeId('u1'), const PrizeId('p1')});
    expect(s.game.raffle, isNull);
    expect(s.game.isWon(const PrizeId('p2')), isFalse);
    expect(s.game.openPrizes.map((p) => p.id), contains(const PrizeId('p2')));
    s.dispose();
  });
}

String _seed(int i) => List.filled(64, '0123456789abcdef'[i % 16]).join();

final class _Secrets implements HostSecretStore {
  _Secrets(this.seed);
  final String seed;

  @override
  Future<String?> loadDrawSeed(GameId id) async => seed;

  @override
  Future<void> saveDrawSeed(GameId id, String seedHex) async {}
}

final class _Scenario {
  _Scenario._(this.repo, this.id, this.host, this.cards);

  final LocalGameRepository repo;
  final GameId id;
  final HostPanelController host;
  final Map<UserId, BingoCard> cards;

  Game get game => host.game!;

  static Future<_Scenario> start(
    List<String> uids, {
    String seed = drawSeed,
    OverLimitRule overLimit = OverLimitRule.backToGame,
  }) async {
    final repo = LocalGameRepository(KeyValueStore.memory());
    final secrets = _Secrets(seed);
    const seq = DrawSequence();
    const tie = TieBreaker();
    const underdog = UnderdogCalculator();
    final draft = makeGame(policy: const PrizePolicy(maxPerPlayer: 2)).copyWith(
      hostUid: const UserId('host'),
      drawCommit: seq.commitOf(seed),
      settings: GameSettings(overLimit: overLimit),
    );
    final g = await repo.createGame(draft);
    final cards = <UserId, BingoCard>{};
    for (final u in uids) {
      final uid = UserId(u);
      final card = const CardGenerator().generate(
        uid: uid,
        gameId: g.id,
        salt: g.salt,
        template: g.template,
      );
      cards[uid] = card;
      await repo.join(
        g.id,
        player: Player(uid: uid, displayName: u, joinedAt: DateTime.utc(2026)),
        email: '$u@example.com',
        card: card,
      );
    }
    await repo.start(g.id, cardsHash: seq.cardsHash(cards.values.toList()));
    final end = EndGame(repo, secrets, seq, underdog, tie);
    final host = HostPanelController(
      code: g.roomCode,
      repository: repo,
      drawNext: DrawNext(repo, secrets, seq),
      verifyClaim: VerifyClaim(
        repo,
        const BingoVerifier(),
        const CardGenerator(),
      ),
      resolveClaim: ResolveClaim(repo),
      resolveTie: ResolveTie(secrets, seq, tie),
      confirmPrize: ConfirmPrize(repo, end),
      endGame: end,
      awardUnderdog: AwardUnderdog(repo, secrets, seq, underdog, tie),
    );
    await host.start();
    final s = _Scenario._(repo, g.id, host, cards);
    await s.settle();
    return s;
  }

  Future<void> settle() => pumpEventQueue(times: 200);

  void dispose() => host.dispose();

  Set<ItemId> numbers(UserId u) => {
    for (final (i, c) in cards[u]!.cells.indexed)
      if (c != null && i != game.template.freeCellIndex) c,
  };

  Set<PrizeId> held(UserId u) => {
    for (final w in game.winners)
      if (w.uid == u) w.prizeId,
  };

  Claim claim(Claim c) => host.claims.firstWhere((o) => o.id == c.id);

  Future<void> draw(ItemId item) async {
    if (game.draws.contains(item)) return;
    await repo.appendDraw(id, item);
    await settle();
  }

  Future<Claim> bingo(UserId u, PrizeId prize, List<int> cells) async {
    final cid = await repo.createClaim(
      id,
      Claim(
        id: const ClaimId('new'),
        uid: u,
        prizeId: prize,
        drawIndex: game.draws.length,
        markedCells: cells,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await settle();
    return host.claims.firstWhere((c) => c.id == cid);
  }

  /// Everyone but two players leaves the azarão; then those two fall on the
  /// same ball. The host draws the tie. Returns (winner, the other).
  Future<(UserId, UserId)> underdogTieAndRaffle() async {
    final uids = cards.keys.toList();
    for (var a = 0; a < uids.length; a++) {
      for (var b = a + 1; b < uids.length; b++) {
        final pair = {uids[a], uids[b]};
        final both = numbers(uids[a]).intersection(numbers(uids[b]));
        final shield = numbers(uids[a]).union(numbers(uids[b]));
        final outs = <ItemId>[];
        var ok = both.isNotEmpty;
        for (final o in uids.where((u) => !pair.contains(u))) {
          final hit = numbers(o).difference(shield);
          if (hit.isEmpty) ok = false;
          if (ok) outs.add(hit.first);
        }
        if (!ok) continue;
        for (final ball in outs) {
          await draw(ball);
        }
        expect(game.raffle, isNull, reason: 'two still standing');
        await draw(both.first);
        final r = game.raffle!;
        expect(r.kind, RaffleKind.underdogTie);
        expect(r.candidates.toSet(), pair);
        expect(game.isWon(const PrizeId('u1')), isFalse);
        expect(host.drawBlockedReason, isNotNull);
        expect(await host.runRaffle(), isTrue);
        await settle();
        final w = game.raffle!.winner!;
        expect(held(w), {const PrizeId('u1')});
        return (w, pair.firstWhere((u) => u != w));
      }
    }
    fail('no card layout for an azarão tie');
  }

  /// [u] completes the first row and the host confirms it.
  Future<void> winHorizontal(UserId u) async {
    final row = [0, 1, 2, 3, 4];
    for (final i in row) {
      await draw(cards[u]!.cells[i]!);
    }
    final c = await bingo(u, const PrizeId('p1'), row);
    expect(host.results[c.id]?.verdict, ClaimVerdict.valid);
    expect(await host.confirmSingle(c), isTrue);
    await settle();
  }

  List<int> column(int k) => [for (var r = 0; r < 5; r++) r * 5 + k];

  /// [w] and [y] close a column on the same ball.
  Future<(Claim, Claim)> verticalTie(UserId w, UserId y) async {
    for (final k in [0, 1, 3, 4]) {
      final cw = {for (final i in column(k)) cards[w]!.cells[i]!};
      final cy = {for (final i in column(k)) cards[y]!.cells[i]!};
      final shared = cw.intersection(cy).where((b) => !game.draws.contains(b));
      if (shared.isEmpty) continue;
      final last = shared.first;
      for (final b in {...cw, ...cy}) {
        if (b != last) await draw(b);
      }
      await draw(last);
      final a = await bingo(w, const PrizeId('p2'), column(k));
      final b = await bingo(y, const PrizeId('p2'), column(k));
      await settle();
      expect(host.results[a.id]?.verdict, ClaimVerdict.valid);
      expect(host.results[b.id]?.verdict, ClaimVerdict.valid);
      return (a, b);
    }
    fail('no shared column ball');
  }

  /// [w] alone closes a column (no tie) while already at the limit.
  Future<Claim> winVerticalAlone(UserId w) async {
    for (final i in column(0)) {
      await draw(cards[w]!.cells[i]!);
    }
    final c = await bingo(w, const PrizeId('p2'), column(0));
    expect(host.tiedFor(c), isEmpty);
    expect(await host.confirmSingle(c), isTrue);
    await settle();
    return c;
  }
}
