import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/pattern_detector.dart';
import 'package:tokingo/features/game/domain/services/penalty_evaluator.dart';

/// Checks a claim against public data (§5). Pure and deterministic.
///
/// Rules: card must equal the regenerated card (else `tampered`); player must
/// be eligible (R30, else `notEligible`) and not blocked (R31, `penalized`);
/// only draws[0..claim.drawIndex) count; any marked cell not drawn → `missed`;
/// cells counted = marked ∩ drawn (+ free cell); current prize pattern
/// complete → `valid`; another pattern complete → `wrongPattern`; else `missed`.
final class BingoVerifier {
  const BingoVerifier();

  static const _detector = PatternDetector();

  static bool _sameCells(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  ClaimResult verify({
    required Game game,
    required Claim claim,
    required BingoCard card,
    required BingoCard expectedCard,
    required List<Claim> history,
  }) {
    if (!_sameCells(card.cells, expectedCard.cells)) {
      return const ClaimResult(
        verdict: ClaimVerdict.tampered,
        reason: 'Cartela não confere com a seed',
      );
    }
    final open = game.openPrizes;
    if (open.isEmpty) {
      return const ClaimResult(
        verdict: ClaimVerdict.wrongPattern,
        reason: 'Nenhum prêmio em jogo',
      );
    }
    // Several prizes can be open at once (e.g. Horizontal + Vertical).
    final prize = open.firstWhere(
      (p) => p.id == claim.prizeId,
      orElse: () => open.first,
    );
    // No prize-limit block: a player holding a prize may still claim; the
    // host then asks them to keep the old prize or swap (awaitingChoice).
    final block = const PenaltyEvaluator().blockFor(
      uid: claim.uid,
      policy: game.settings.claimPenalty,
      history: [
        for (final c in history)
          if (c.id != claim.id) c,
      ],
      currentDrawIndex: claim.drawIndex,
    );
    if (block != null) {
      return ClaimResult(verdict: ClaimVerdict.penalized, reason: block.reason);
    }

    final t = game.template;
    final free = t.freeCellIndex;
    final drawn = game.draws.take(claim.drawIndex).toSet();
    final notDrawn = [
      for (final i in claim.markedCells.toSet())
        if (i != free && i >= 0 && i < card.cells.length)
          if (card.cells[i] case final id? when !drawn.contains(id)) id,
    ];
    if (notDrawn.isNotEmpty) {
      final first = notDrawn.first;
      final h = first.column < t.headers.length ? t.headers[first.column] : '';
      final label = '$h ${t.item(first).label}'.trim();
      return ClaimResult(
        verdict: ClaimVerdict.missed,
        notDrawn: notDrawn,
        reason: 'Marcou $label que ainda não saiu',
      );
    }
    final filled = <int>{
      for (final i in claim.markedCells)
        if (i >= 0 && i < card.cells.length && card.cells[i] != null) i,
      ?free,
    };
    List<PatternMatch> check(Prize p) => _detector.completed(
      filled: filled,
      rows: t.rows,
      cols: t.cols,
      prize: p,
    );

    if (claim.prizeId == prize.id) {
      final matched = check(prize);
      if (matched.isNotEmpty) {
        return ClaimResult(
          verdict: ClaimVerdict.valid,
          matched: matched,
          reason: 'Válido',
        );
      }
    }
    final others = <PatternMatch>{
      for (final p in game.prizes)
        if (p.id != prize.id && p.order != null) ...check(p),
      for (final k in [
        PatternKind.horizontal,
        PatternKind.vertical,
        PatternKind.diagonal,
      ])
        ...check(Prize(id: prize.id, label: '', pattern: k)),
    }.toList();
    if (claim.prizeId != prize.id || others.isNotEmpty) {
      return ClaimResult(
        verdict: ClaimVerdict.wrongPattern,
        matched: others,
        reason: claim.prizeId != prize.id
            ? 'Prêmio do grito não está valendo'
            : 'Modalidade errada',
      );
    }
    return const ClaimResult(
      verdict: ClaimVerdict.missed,
      reason: 'Nenhum padrão completo',
    );
  }

  /// Valid claims for the current prize sharing the smallest drawIndex (R28).
  List<Claim> tiedValidClaims(List<Claim> verifiedClaims) {
    final valid = [
      for (final c in verifiedClaims)
        if (c.verdict == ClaimVerdict.valid &&
            (c.status == ClaimStatus.pending || c.status == ClaimStatus.tied))
          c,
    ];
    if (valid.isEmpty) return const [];
    final min = valid.map((c) => c.drawIndex).reduce((a, b) => a < b ? a : b);
    final tied = [
      for (final c in valid)
        if (c.drawIndex == min) c,
    ];
    return tied.length > 1 ? tied : const [];
  }
}
