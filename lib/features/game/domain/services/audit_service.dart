import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/services/card_generator.dart';
import 'package:tokingo/features/game/domain/services/draw_sequence.dart';
import 'package:tokingo/features/game/domain/services/prize_policy_evaluator.dart';
import 'package:tokingo/features/game/domain/services/underdog_calculator.dart';

final class AuditCheck {
  const AuditCheck({
    required this.title,
    required this.detail,
    required this.ok,
    required this.result,
    this.technical = '',
  });

  /// Plain-language name of what was checked.
  final String title;

  /// Plain-language explanation.
  final String detail;
  final bool ok;

  /// Short result label, e.g. "ok", "61/61".
  final String result;

  /// Optional formula/hash line for technical readers (shown in mono).
  final String technical;
}

/// /verify (16): recomputes everything from public data + revealed seed.
final class AuditService {
  const AuditService();

  static const _policy = PrizePolicyEvaluator();

  /// Statuses of a claim the host judged valid (won, tied, chose, gave up).
  static const Set<ClaimStatus> _validStatuses = {
    ClaimStatus.confirmed,
    ClaimStatus.tied,
    ClaimStatus.awaitingChoice,
    ClaimStatus.declined,
  };

  /// Verdict the host recorded; a valid claim later tied/declined/swapped
  /// may carry only its status.
  static ClaimVerdict? _storedVerdict(Claim c) =>
      c.verdict ??
      (_validStatuses.contains(c.status) ? ClaimVerdict.valid : null);

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
      String technical = '',
    }) => AuditCheck(
      title: title,
      detail: detail,
      ok: good == total,
      result: ratio ? '$good/$total' : (good == total ? 'ok' : 'falhou'),
      technical: technical,
    );

    // 1. Commit.
    final commitOk = ds.commitOf(seed) == game.drawCommit;
    checks.add(
      check(
        'Sorteio definido antes do jogo começar',
        'O segredo revelado no fim bate com o lacre publicado na criação da '
            'sala: ninguém mudou a ordem das bolas no meio do jogo.',
        commitOk ? 1 : 0,
        1,
        ratio: false,
        technical: 'sha256(drawSeed) = drawCommit',
      ),
    );

    // 2. Final seed from cardsHash.
    final cardsHash = ds.cardsHash(cards);
    final hashOk = game.cardsHash == null || game.cardsHash == cardsHash;
    final finalSeed = ds.finalSeed(drawSeedHex: seed, cardsHash: cardsHash);
    checks.add(
      check(
        'Cartelas travadas no início',
        'As cartelas publicadas são as mesmas que existiam quando o jogo '
            'começou e entram no cálculo do sorteio.',
        hashOk ? 1 : 0,
        1,
        ratio: false,
        technical: 'sha256(drawSeed | cardsHash)',
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
        'Bolas sorteadas na ordem certa',
        'Cada bola que saiu é exatamente a próxima da sequência calculada.',
        drawOk,
        game.draws.length,
        technical: 'draws = prefixo da permutação do pool',
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
        'Cartelas sem alteração',
        'Cada cartela foi gerada de novo a partir do jogador e da sala e '
            'saiu idêntica.',
        cardOk,
        cards.length,
        technical: 'sha256(uid | gameId | salt) → mulberry32',
      ),
    );

    // 5. Claim verdicts, against the prizes that were open at each claim.
    final byUid = {for (final c in cards) c.owner: c};
    final sortedClaims = [...claims]
      ..sort((a, b) {
        final d = a.drawIndex.compareTo(b.drawIndex);
        return d != 0 ? d : a.createdAt.compareTo(b.createdAt);
      });
    var claimOk = 0;
    var claimTotal = 0;
    for (final cl in sortedClaims) {
      final stored = _storedVerdict(cl);
      // Never judged (game ended with it pending): nothing to compare.
      if (stored == null) continue;
      claimTotal++;
      final card = byUid[cl.uid];
      final exp = expected[cl.uid];
      if (card == null || exp == null) continue;
      final history = [
        for (final h in sortedClaims)
          if (h.drawIndex < cl.drawIndex) h,
      ];
      final ok = _winnersAt(game, sortedClaims, cl).any((winners) {
        final r = const BingoVerifier().verify(
          game: game.copyWith(winners: winners),
          claim: cl,
          card: card,
          expectedCard: exp,
          history: history,
        );
        return r.verdict == stored;
      });
      if (ok) claimOk++;
    }
    checks.add(
      check(
        'Pedidos de BINGO conferidos de novo',
        'Cada BINGO gritado foi reconferido com as bolas que já tinham saído '
            'e os prêmios em jogo naquele momento; o resultado é o mesmo que '
            'o host deu.',
        claimOk,
        claimTotal,
      ),
    );

    // 6. Every pattern prize went to a valid claim, within the limits.
    final endIds = {for (final p in game.endOfGamePrizes) p.id};
    var prizeGood = 0;
    var prizeTotal = 0;
    for (final p in game.prizes) {
      final ws = game.winnersOf(p.id);
      if (ws.isEmpty) continue;
      final countOk =
          game.settings.tieBreak != TieBreakRule.draw || ws.length <= p.winners;
      for (final w in ws) {
        prizeTotal++;
        final valid = claims.any(
          (c) =>
              c.uid == w.uid &&
              c.drawIndex == w.drawIndex &&
              (c.prizeId == p.id || c.offerPrizeId == p.id) &&
              _storedVerdict(c) == ClaimVerdict.valid,
        );
        if (valid && countOk) prizeGood++;
      }
    }
    checks.add(
      check(
        'Prêmios entregues a BINGOs válidos',
        'Cada ganhador tem um BINGO válido para aquele prêmio, e nenhum '
            'prêmio teve mais ganhadores do que o previsto.',
        prizeGood,
        prizeTotal,
      ),
    );

    // 7. Prize limit per person.
    final holders = {for (final w in game.winners) w.uid};
    var limitOk = 0;
    for (final uid in holders) {
      if (_policy.canHold(
        _policy.heldBy(uid, game.winners),
        game.prizePolicy,
      )) {
        limitOk++;
      }
    }
    checks.add(
      check(
        'Limite de prêmios por pessoa respeitado',
        'Ninguém ficou com mais prêmios (ou com uma combinação) do que a '
            'regra da sala permite.',
        limitOk,
        holders.length,
      ),
    );

    // 8. Underdog.
    var underOk = true;
    final seqWinners = [
      for (final w in game.winners)
        if (!endIds.contains(w.prizeId)) w,
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
        'Azarão calculado de novo',
        'A cada bola sai da disputa quem tem aquele número na cartela; o '
            'último a sobrar é o mesmo ganhador registrado.',
        underOk ? 1 : 0,
        1,
        ratio: false,
      ),
    );
    return checks;
  }

  /// Plausible winners lists at the moment of [cl]. Winners change over the
  /// game (swaps, prizes given up and passed on), so the audit rebuilds the
  /// prizes that were open from several angles and accepts the stored verdict
  /// when any of them reproduces it:
  /// 1. final winners recorded before the claim's ball;
  /// 2. the same plus winners on the same ball (claim verified after a
  ///    tie-mate was already confirmed);
  /// 3. prizes taken by earlier valid claims (covers prizes later swapped);
  /// 4. 3 plus earlier-confirmed claims on the same ball.
  static List<List<Winner>> _winnersAt(
    Game game,
    List<Claim> sorted,
    Claim cl,
  ) {
    final seqIds = {for (final p in game.prizes) p.id};
    bool other(UserId uid, int i) => !(uid == cl.uid && i == cl.drawIndex);
    final recorded = [
      for (final w in game.winners)
        if (seqIds.contains(w.prizeId) && w.drawIndex < cl.drawIndex) w,
    ];
    final recordedSame = [
      for (final w in game.winners)
        if (seqIds.contains(w.prizeId) &&
            w.drawIndex <= cl.drawIndex &&
            other(w.uid, w.drawIndex))
          w,
    ];
    List<Winner> fromClaims({required bool sameBall}) => [
      for (final c in sorted)
        if (c.id != cl.id &&
            (c.drawIndex < cl.drawIndex ||
                (sameBall &&
                    c.drawIndex == cl.drawIndex &&
                    c.status == ClaimStatus.confirmed &&
                    c.uid != cl.uid)) &&
            _storedVerdict(c) == ClaimVerdict.valid &&
            _validStatuses.contains(c.status))
          Winner(prizeId: c.prizeId, uid: c.uid, drawIndex: c.drawIndex),
    ];
    return [
      recorded,
      recordedSame,
      fromClaims(sameBall: false),
      fromClaims(sameBall: true),
    ];
  }

  static bool _same(List<ItemId?> a, List<ItemId?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
