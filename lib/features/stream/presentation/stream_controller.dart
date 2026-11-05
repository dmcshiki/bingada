import 'dart:async';

import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/sound/bingo_sound.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_watch_controller.dart';

/// Overlays of the streamer (R29): 13b–13f.
sealed class StreamOverlay {
  const StreamOverlay();
}

/// 13b – host is checking [claim].
final class CheckingOverlay extends StreamOverlay {
  const CheckingOverlay(this.claim);
  final Claim claim;
}

/// 13c – valid; [prize] delivered, [next] is what now counts.
final class ValidOverlay extends StreamOverlay {
  const ValidOverlay({required this.claim, required this.prize, this.next});
  final Claim claim;
  final Prize? prize;
  final Prize? next;
}

/// 13d – rejected claim: "comeu bola" ([ClaimVerdict.missed]) or wrong
/// pattern ([ClaimVerdict.wrongPattern]). Only with showFailsOnStream.
final class MissedOverlay extends StreamOverlay {
  const MissedOverlay(this.claim);
  final Claim claim;

  bool get wrongPattern => claim.verdict == ClaimVerdict.wrongPattern;
}

/// A valid claim whose player already holds a prize is choosing which one
/// to keep ([ClaimStatus.awaitingChoice]).
final class ChoosingOverlay extends StreamOverlay {
  const ChoosingOverlay({required this.claim, required this.offered});
  final Claim claim;
  final Prize? offered;
}

/// Outcome of a choice: [swapped] (took [offered]) or kept the old prize.
final class ChoiceOverlay extends StreamOverlay {
  const ChoiceOverlay({
    required this.claim,
    required this.offered,
    required this.swapped,
  });
  final Claim claim;
  final Prize? offered;
  final bool swapped;
}

/// 13e (winners == null) / 13f (winners decided).
final class TieOverlay extends StreamOverlay {
  const TieOverlay({
    required this.tied,
    required this.prize,
    this.winners,
    this.next,
  });
  final List<Claim> tied;
  final Prize? prize;
  final Set<UserId>? winners;
  final Prize? next;
}

/// Host draw of a prize (azarão tie or one given up); [Raffle.winner] null
/// while waiting for the host.
final class RaffleOverlay extends StreamOverlay {
  const RaffleOverlay(this.raffle);
  final Raffle raffle;
}

/// Azarão decided mid-game: the last player left standing.
final class UnderdogOverlay extends StreamOverlay {
  const UnderdogOverlay({required this.prize, required this.winners});
  final Prize prize;
  final List<Winner> winners;
}

/// Read-only model of the stream. It never writes: verification of pending
/// claims is recomputed locally from public data only to detect ties (13e).
class StreamController extends GameWatchController {
  StreamController({
    required super.code,
    required super.repository,
    super.trackUnderdog = true,
    VerifyClaim? verifyClaim,
    this._verifier = const BingoVerifier(),
    this.flashDuration = const Duration(seconds: 8),
  }) : _verify = verifyClaim;

  final VerifyClaim? _verify;
  final BingoVerifier _verifier;
  final Duration flashDuration;

  final Map<ClaimId, ClaimStatus> _seen = {};
  final Map<ClaimId, ClaimVerdict> _localVerdicts = {};
  final Set<ClaimId> _verifying = {};

  StreamOverlay? _flash;
  Timer? _flashTimer;
  @override
  void notifyListeners() {
    if (game case final g?) _verifyPending(g);
    super.notifyListeners();
  }

  @override
  void onGameChanged(Game? previous, Game next) {
    super.onGameChanged(previous, next);
    if (previous == null || next.status != GameStatus.running) return;
    // A new ball clears the last result so the call is never covered.
    if (next.draws.length > previous.draws.length && _flash != null) {
      _flash = null;
      _flashTimer?.cancel();
    }
    final had = {for (final w in previous.winners) w.prizeId};
    for (final p in next.endOfGamePrizes) {
      if (p.pattern != PatternKind.underdog || had.contains(p.id)) continue;
      final ws = [
        for (final w in next.winners)
          if (w.prizeId == p.id) w,
      ];
      if (ws.isNotEmpty) _setFlash(UnderdogOverlay(prize: p, winners: ws));
    }
  }

  @override
  void onClaimsChanged(List<Claim> next, {required bool first}) {
    final g = game;
    for (final c in next) {
      final before = _seen[c.id];
      _seen[c.id] = c.status;
      // Do not replay old results when the stream opens mid-game.
      if (first || g == null || before == c.status) continue;
      if (c.status == ClaimStatus.pending && before == null) {
        playBingoChime();
      } else if (c.status == ClaimStatus.confirmed) {
        if (before == ClaimStatus.awaitingChoice) {
          _setFlash(
            ChoiceOverlay(claim: c, offered: _offered(g, c), swapped: true),
          );
        } else {
          _onConfirmed(g, c, next);
        }
      } else if (c.status == ClaimStatus.declined) {
        _setFlash(
          ChoiceOverlay(claim: c, offered: _offered(g, c), swapped: false),
        );
      } else if (c.status == ClaimStatus.rejected &&
          (c.verdict == ClaimVerdict.missed ||
              c.verdict == ClaimVerdict.wrongPattern) &&
          g.settings.showFailsOnStream) {
        _setFlash(MissedOverlay(c));
      }
    }
  }

  void _onConfirmed(Game g, Claim c, List<Claim> all) {
    final tied = [
      for (final o in all)
        if (o.prizeId == c.prizeId &&
            o.drawIndex == c.drawIndex &&
            (o.status == ClaimStatus.tied || o.status == ClaimStatus.confirmed))
          o,
    ];
    final prize = _prize(g, c.prizeId);
    // Winners/currentPrize may land in the game doc slightly later; the
    // overlay reads them live from [game] when rendering.
    if (tied.length > 1) {
      _setFlash(
        TieOverlay(
          tied: tied,
          prize: prize,
          winners: {
            for (final o in tied)
              if (o.status == ClaimStatus.confirmed) o.uid,
          },
        ),
      );
    } else {
      _setFlash(ValidOverlay(claim: c, prize: prize));
    }
  }

  Prize? _offered(Game g, Claim c) => _prize(g, c.offerPrizeId ?? c.prizeId);

  Prize? _prize(Game g, PrizeId id) {
    for (final p in [...g.prizes, ...g.endOfGamePrizes]) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _verifyPending(Game g) {
    final v = _verify;
    if (v == null) return;
    for (final c in claims) {
      if (c.status != ClaimStatus.pending) continue;
      if (_localVerdicts.containsKey(c.id) || _verifying.contains(c.id)) {
        continue;
      }
      _verifying.add(c.id);
      unawaited(() async {
        try {
          final r = await v(g, c, claims);
          _localVerdicts[c.id] = r.verdict;
        } on Object {
          // Read-only view: ignore, it just won't show a tie.
        } finally {
          _verifying.remove(c.id);
          super.notifyListeners();
        }
      }());
    }
  }

  void _setFlash(StreamOverlay o) {
    _flash = o;
    _flashTimer?.cancel();
    _flashTimer = Timer(flashDuration, () {
      _flash = null;
      super.notifyListeners();
    });
  }

  /// Current overlay, by priority: flash result > tie in progress > checking.
  StreamOverlay? get overlay {
    final g = game;
    // An on-screen draw stays up until the next ball.
    if (g?.raffle case final r?) return RaffleOverlay(r);
    if (_flash case final f?) return f;
    if (g == null) return null;
    final pending = pendingClaims;
    if (pending.isEmpty) {
      for (final c in claims) {
        if (c.status == ClaimStatus.awaitingChoice) {
          return ChoosingOverlay(claim: c, offered: _offered(g, c));
        }
      }
      return null;
    }
    final first = ([
      ...pending,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt))).first;
    final prize = g.prizeById(first.prizeId) ?? g.currentPrize;
    final candidates = [
      for (final c in claims)
        if (c.prizeId == first.prizeId)
          switch (_localVerdicts[c.id]) {
            final v? => c.copyWith(verdict: v),
            null => c,
          },
    ];
    final tied = _verifier.tiedValidClaims(candidates);
    if (tied.length > 1 && g.settings.tieBreak == TieBreakRule.draw) {
      return TieOverlay(tied: tied, prize: prize);
    }
    pending.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return CheckingOverlay(pending.first);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }
}
