import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

import 'fixtures.dart';

void main() {
  const ds = DrawSequence();
  const audit = AuditService();
  final cards = [cardOf('alice'), cardOf('bob')];
  final hash = ds.cardsHash(cards);
  final seq = ds.sequence(
    finalSeedHex: ds.finalSeed(drawSeedHex: drawSeed, cardsHash: hash),
    template: template,
  );

  Game finished({String seed = drawSeed}) =>
      makeGame(seed: seed, cardsHash: hash, draws: seq.take(40).toList());

  test('seed not revealed', () {
    final r = audit.audit(game: makeGame(), cards: cards, claims: const []);
    expect(r.single.title, 'Seed ainda não revelada');
    expect(r.single.ok, isFalse);
  });

  test('happy path', () {
    final g = finished();
    final drawn = g.draws.toSet();
    final marked = [
      for (final (i, id) in cards[0].cells.indexed)
        if (id != null && drawn.contains(id)) i,
    ];
    final claim = makeClaim(drawIndex: 40, marked: marked);
    final verdict = const BingoVerifier()
        .verify(
          game: g,
          claim: claim,
          card: cards[0],
          expectedCard: cards[0],
          history: const [],
        )
        .verdict;
    final r = audit.audit(
      game: g,
      cards: cards,
      claims: [claim.copyWith(verdict: verdict)],
    );
    for (final c in r) {
      expect(c.ok, isTrue, reason: c.title);
    }
    expect(r.firstWhere((c) => c.title.startsWith('Bolas')).result, '40/40');
    expect(
      r.firstWhere((c) => c.title.startsWith('Cartelas sem')).result,
      '2/2',
    );
    expect(r.firstWhere((c) => c.title.startsWith('Pedidos')).result, '1/1');
  });

  test('tampered seed fails commit and draws', () {
    final r = audit.audit(
      game: finished(seed: '2' * 64),
      cards: cards,
      claims: const [],
    );
    expect(r.first.ok, isFalse);
    expect(r.firstWhere((c) => c.title.startsWith('Bolas')).ok, isFalse);
  });

  test('tampered card fails regeneration', () {
    final bad = [
      cards[0].copyWith(cells: [...cards[0].cells]..[0] = const ItemId('0:99')),
      cards[1],
    ];
    final r = audit.audit(game: finished(), cards: bad, claims: const []);
    expect(
      r.firstWhere((c) => c.title.startsWith('Cartelas sem')).result,
      '1/2',
    );
  });

  test('simultaneous prizes and a swap pass the audit', () {
    final full = makeGame(seed: drawSeed, cardsHash: hash, draws: seq);
    List<int> marksAt(int card, int n) {
      final drawn = seq.take(n).toSet();
      return [
        for (final (i, id) in cards[card].cells.indexed)
          if (id != null && drawn.contains(id)) i,
      ];
    }

    ClaimVerdict verdictOf(Claim c, int card, List<Winner> winners) =>
        const BingoVerifier()
            .verify(
              game: full.copyWith(winners: winners),
              claim: c,
              card: cards[card],
              expectedCard: cards[card],
              history: const [],
            )
            .verdict;

    int firstValid(int card, PrizeId prize) {
      for (var n = 1; n <= seq.length; n++) {
        final c = makeClaim(
          drawIndex: n,
          uid: cards[card].owner.value,
          prizeId: prize,
          marked: marksAt(card, n),
        );
        if (verdictOf(c, card, const []) == ClaimVerdict.valid) return n;
      }
      return -1;
    }

    const a = UserId('alice');
    const b = UserId('bob');
    final ha = firstValid(0, p1.id);
    final va = firstValid(0, p2.id);
    final hb = firstValid(1, p1.id);
    expect([ha, va, hb], everyElement(greaterThan(0)));
    final x = [ha, va, hb].reduce((m, e) => m > e ? m : e) + 1;
    final c1 = makeClaim(drawIndex: ha, marked: marksAt(0, ha));
    final c2 = makeClaim(
      id: 'c2',
      drawIndex: va,
      prizeId: p2.id,
      marked: marksAt(0, va),
    );
    final c3 = makeClaim(
      id: 'c3',
      uid: 'bob',
      drawIndex: x,
      marked: marksAt(1, x),
    );
    // Alice won Horizontal, then Vertical and gave Horizontal up (limit 1);
    // Bob later took Horizontal back from play.
    final winners = [
      Winner(prizeId: p2.id, uid: a, drawIndex: va),
      Winner(prizeId: p1.id, uid: b, drawIndex: x),
    ];
    final g = full.copyWith(winners: winners);
    final claims = [
      c1.copyWith(
        verdict: verdictOf(c1, 0, const []),
        status: ClaimStatus.confirmed,
      ),
      c2.copyWith(
        verdict: verdictOf(c2, 0, const []),
        status: ClaimStatus.confirmed,
        releasePrizeId: p1.id,
      ),
      c3.copyWith(
        verdict: verdictOf(c3, 1, [winners.first]),
        status: ClaimStatus.confirmed,
      ),
    ];
    final r = audit.audit(game: g, cards: cards, claims: claims);
    for (final c in r) {
      if (c.title.startsWith('Azarão')) continue;
      expect(c.ok, isTrue, reason: '${c.title}: ${c.result}');
    }
    expect(r.firstWhere((c) => c.title.startsWith('Pedidos')).result, '3/3');
  });

  test('wrong stored verdict is detected', () {
    final claim = makeClaim(drawIndex: 40, verdict: ClaimVerdict.valid);
    final r = audit.audit(game: finished(), cards: cards, claims: [claim]);
    expect(r.firstWhere((c) => c.title.startsWith('Pedidos')).ok, isFalse);
  });
}
