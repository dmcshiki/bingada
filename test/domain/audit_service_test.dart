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
    expect(r.firstWhere((c) => c.title.startsWith('Cartelas')).result, '2/2');
    expect(r.firstWhere((c) => c.title.startsWith('Gritos')).result, '1/1');
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
    expect(r.firstWhere((c) => c.title.startsWith('Cartelas')).result, '1/2');
  });

  test('wrong stored verdict is detected', () {
    final claim = makeClaim(drawIndex: 40, verdict: ClaimVerdict.valid);
    final r = audit.audit(game: finished(), cards: cards, claims: [claim]);
    expect(r.firstWhere((c) => c.title.startsWith('Gritos')).ok, isFalse);
  });
}
