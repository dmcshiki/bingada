import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/services/card_generator.dart';
import 'package:tokingo/features/game/domain/services/draw_sequence.dart';
import 'package:tokingo/features/game/domain/services/underdog_calculator.dart';

final class AuditCheck {
  const AuditCheck({
    required this.title,
    required this.detail,
    required this.ok,
    required this.result,
  });

  final String title;
  final String detail;
  final bool ok;

  /// Short result label, e.g. "ok", "61/61".
  final String result;
}

/// /verify (16): recomputes everything from public data + revealed seed.
final class AuditService {
  const AuditService();

  List<AuditCheck> audit({
    required Game game,
    required List<BingoCard> cards,
    required List<Claim> claims,
  }) {
    final seed = game.drawSeed;
    if (seed == null) {
      return const [
        AuditCheck(
          title: 'Seed ainda não revelada',
          detail: 'A auditoria fica disponível quando o jogo termina.',
          ok: false,
          result: 'pendente',
        ),
      ];
    }
    const ds = DrawSequence();
    const gen = CardGenerator();
    final checks = <AuditCheck>[];
    AuditCheck check(
      String title,
      String detail,
      int good,
      int total, {
      bool ratio = true,
    }) => AuditCheck(
      title: title,
      detail: detail,
      ok: good == total,
      result: ratio ? '$good/$total' : (good == total ? 'ok' : 'falhou'),
    );

    // 1. Commit.
    final commitOk = ds.commitOf(seed) == game.drawCommit;
    checks.add(
      check(
        'Commit confere com a seed revelada',
        'sha256(drawSeed) = drawCommit',
        commitOk ? 1 : 0,
        1,
        ratio: false,
      ),
    );

    // 2. Final seed from cardsHash.
    final cardsHash = ds.cardsHash(cards);
    final hashOk = game.cardsHash == null || game.cardsHash == cardsHash;
    final finalSeed = ds.finalSeed(drawSeedHex: seed, cardsHash: cardsHash);
    checks.add(
      check(
        'Seed final recalculada',
        'sha256(drawSeed | cardsHash) a partir das cartelas publicadas',
        hashOk ? 1 : 0,
        1,
        ratio: false,
      ),
    );

    // 3. Draws are the sequence prefix.
    final seq = ds.sequence(finalSeedHex: finalSeed, template: game.template);
    var drawOk = 0;
    for (var i = 0; i < game.draws.length; i++) {
      if (i < seq.length && seq[i] == game.draws[i]) drawOk++;
    }
    checks.add(
      check(
        'Bolas sorteadas batem com a sequência',
        'draws = prefixo da permutação do pool',
        drawOk,
        game.draws.length,
      ),
    );

    // 4. Every card regenerates.
    final expected = <UserId, BingoCard>{};
    var cardOk = 0;
    for (final c in cards) {
      final e = gen.generate(
        uid: c.owner,
        gameId: game.id,
        salt: game.salt,
        template: game.template,
      );
      expected[c.owner] = e;
      if (_same(c.cells, e.cells)) cardOk++;
    }
    checks.add(
      check(
        'Cartelas regeneradas pela seed',
        'sha256(uid | gameId | salt) → mulberry32',
        cardOk,
        cards.length,
      ),
    );

    // 5. Claim verdicts. Replays the game prize by prize.
    final byUid = {for (final c in cards) c.owner: c};
    final sortedClaims = [...claims]
      ..sort((a, b) {
        final d = a.drawIndex.compareTo(b.drawIndex);
        return d != 0 ? d : a.createdAt.compareTo(b.createdAt);
      });
    var claimOk = 0;
    for (final cl in sortedClaims) {
      final card = byUid[cl.uid];
      if (card == null) continue;
      final winnersBefore = [
        for (final w in game.winners)
          if (w.drawIndex < cl.drawIndex) w,
      ];
      final idx = game.prizes.indexWhere((p) => p.id == cl.prizeId);
      final replay = game.copyWith(
        winners: winnersBefore,
        currentPrizeIndex: idx < 0 ? game.currentPrizeIndex : idx,
      );
      final r = const BingoVerifier().verify(
        game: replay,
        claim: cl,
        card: card,
        expectedCard: expected[cl.uid]!,
        history: [
          for (final h in sortedClaims)
            if (h.drawIndex < cl.drawIndex) h,
        ],
      );
      if (r.verdict == cl.verdict) claimOk++;
    }
    checks.add(
      check(
        'Gritos revalidados',
        'veredito recalculado = veredito gravado',
        claimOk,
        claims.length,
      ),
    );

    // 6. Prizes order / modalities.
    final seqPrizes = [...game.prizes]
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    var prizeOk = true;
    var lastDraw = -1;
    for (final p in seqPrizes) {
      final ws = [
        for (final w in game.winners)
          if (w.prizeId == p.id) w,
      ];
      if (ws.isEmpty) continue;
      if (game.settings.tieBreak == TieBreakRule.draw &&
          ws.length > p.winners) {
        prizeOk = false;
      }
      for (final w in ws) {
        if (w.drawIndex < lastDraw) prizeOk = false;
        final valid = claims.any(
          (c) =>
              c.uid == w.uid &&
              c.prizeId == p.id &&
              c.verdict == ClaimVerdict.valid &&
              c.drawIndex == w.drawIndex,
        );
        if (!valid) prizeOk = false;
      }
      lastDraw = ws.map((w) => w.drawIndex).reduce((a, b) => a > b ? a : b);
    }
    checks.add(
      check(
        'Prêmios na ordem e modalidades corretas',
        'cada vencedor tem um grito válido no prêmio da vez',
        prizeOk ? 1 : 0,
        1,
        ratio: false,
      ),
    );

    // 7. Underdog.
    var underOk = true;
    final seqIds = {for (final p in game.prizes) p.id};
    final seqWinners = [
      for (final w in game.winners)
        if (seqIds.contains(w.prizeId)) w,
    ];
    for (final u in game.endOfGamePrizes) {
      final stored = {
        for (final w in game.winners)
          if (w.prizeId == u.id) w.uid,
      };
      if (stored.isEmpty) continue;
      final outcome = const UnderdogCalculator().run(
        cards: cards,
        draws: game.draws,
        underdogPrize: u,
        winners: seqWinners,
        policy: game.prizePolicy,
        freeCellIndex: game.template.freeCellIndex,
        gameOver:
            game.status == GameStatus.finished ||
            game.status == GameStatus.abandoned,
      );
      if (!outcome.decided || !outcome.survivors.toSet().containsAll(stored)) {
        underOk = false;
      }
    }
    checks.add(
      check(
        'Azarão recalculado',
        'último a sobrar: sai quem tem a bola sorteada, respeitando o limite',
        underOk ? 1 : 0,
        1,
        ratio: false,
      ),
    );
    return checks;
  }

  static bool _same(List<ItemId?> a, List<ItemId?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
