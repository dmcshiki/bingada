import 'dart:async';

import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/toast.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/penalty_evaluator.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_watch_controller.dart';

/// Overlay 10 state, derived from the player's own latest claim.
enum ClaimOverlayKind {
  waiting,
  valid,
  missed,
  wrongPattern,
  tieLost,
  other,

  /// Valid claim, but the player already holds a prize: keep or swap.
  choose,

  /// The player kept the prize they already had.
  kept,

  /// Tie while at the limit: join the draw or skip it.
  optIn,

  /// The player skipped a tie (stays with their prizes).
  skipped,
}

/// A prize that was just delivered (09c).
final class DeliveredPrize {
  const DeliveredPrize({required this.prize, required this.winners, this.next});

  final Prize prize;
  final List<Winner> winners;
  final Prize? next;
}

/// State of the player screen (09/10). Marks are manual and local (R13):
/// this controller never compares marks with draws.
class PlayerGameController extends GameWatchController {
  PlayerGameController({
    required super.code,
    required super.repository,
    required this._auth,
    required this._marks,
    required this._callBingo,
    super.presence,
    this._penalty = const PenaltyEvaluator(),
  }) : _repoRef = repository;

  final GameRepository _repoRef;
  final AuthRepository _auth;
  final MarksStore _marks;
  final CallBingo _callBingo;
  final PenaltyEvaluator _penalty;

  BingoCard? card;
  Set<int> marked = {};
  bool sending = false;
  String? sendError;

  /// Claim id the overlay follows; null when dismissed.
  ClaimId? _followed;
  DeliveredPrize? delivered;

  AppUser? get user => _auth.currentUser;

  /// True once the card lookup finished (the card itself may be null).
  bool cardChecked = false;

  bool get isHost => game != null && user != null && game!.hostUid == user!.uid;

  @override
  Future<void> start() async {
    await super.start();
    final g = game;
    final u = user;
    if (g == null || u == null) return;
    try {
      card = await _repoRef.getCard(g.id, u.uid);
      marked = await _marks.load(g.id, u.uid);
      cardChecked = true;
    } on Object catch (e) {
      error = e;
    }
    notifyListeners();
  }

  /// Pending claim ids already seen (chime only for new ones).
  final Set<ClaimId> _seenPending = {};

  /// Called once per NEW pending claim from anyone (not on initial load).
  void Function()? onNewPendingClaim;

  final _toasts = StreamController<ToastData>.broadcast();

  /// Game notifications for this player (other people's events).
  Stream<ToastData> get toasts => _toasts.stream;

  final Map<ClaimId, ClaimStatus> _lastStatus = {};

  void _toast(ToastData t) {
    if (!_toasts.isClosed) _toasts.add(t);
  }

  String _first(UserId uid) => playerName(players, uid).split(' ').first;

  @override
  void onClaimsChanged(List<Claim> next, {required bool first}) {
    var fresh = false;
    final me = user?.uid;
    for (final c in next) {
      if (c.status == ClaimStatus.pending && _seenPending.add(c.id)) {
        fresh = true;
      }
      final before = _lastStatus[c.id];
      _lastStatus[c.id] = c.status;
      // Own claims have their own overlay; old ones are not replayed.
      if (first || c.uid == me || before == c.status) continue;
      if (before == null && c.status == ClaimStatus.pending) {
        _toast(
          ToastData(
            title: '${_first(c.uid)} pediu BINGO!',
            body: 'O host está conferindo a cartela.',
            kind: ToastKind.bingo,
          ),
        );
      } else if (c.status == ClaimStatus.declined && c.tieOptIn) {
        _toast(
          ToastData(
            title: '${_first(c.uid)} pulou o desempate',
            body: 'Já estava no limite de prêmios.',
          ),
        );
      } else if (c.status == ClaimStatus.declined) {
        final p = game?.prizeById(c.offerPrizeId ?? c.prizeId);
        _toast(
          ToastData(
            title: '${_first(c.uid)} ficou com os prêmios que já tinha',
            body: p == null ? null : '${p.label} segue a regra da sala.',
          ),
        );
      } else if (c.status == ClaimStatus.rejected) {
        _toast(
          ToastData(
            title: c.verdict == ClaimVerdict.wrongPattern
                ? '${_first(c.uid)} errou a modalidade'
                : '${_first(c.uid)} comeu bola',
            body: 'O jogo continua.',
            kind: ToastKind.miss,
          ),
        );
      }
    }
    if (fresh && !first) onNewPendingClaim?.call();
  }

  @override
  void dispose() {
    unawaited(_toasts.close());
    super.dispose();
  }

  /// Text shown instead of the current ball while the host checks a BINGO
  /// or decides a tie; null when nothing is pending.
  String? get checkingLabel {
    final groups = <(PrizeId, int), int>{};
    for (final c in claims) {
      if (c.status != ClaimStatus.pending) continue;
      final k = (c.prizeId, c.drawIndex);
      groups[k] = (groups[k] ?? 0) + 1;
    }
    if (groups.isEmpty) return null;
    return groups.values.any((n) => n >= 2)
        ? 'desempate em andamento…'
        : 'conferindo um BINGO…';
  }

  @override
  void onGameChanged(Game? previous, Game next) {
    // A draw the host is about to run (azarão tie or a prize given up).
    final r = next.raffle;
    if (previous != null &&
        r != null &&
        r.winner == null &&
        previous.raffle?.prizeId != r.prizeId) {
      final prize = next.prizeById(r.prizeId);
      final names = [for (final u in r.candidates) _first(u)];
      final me = user?.uid;
      final among = names.length <= 4
          ? names.join(', ')
          : '${names.length} pessoas';
      _toast(
        ToastData(
          title: switch (r.kind) {
            RaffleKind.underdogTie => 'Empate no azarão!',
            RaffleKind.released when r.releasedBy != null =>
              '${_first(r.releasedBy!)} abriu mão de ${prize?.label ?? 'um prêmio'}',
            RaffleKind.released =>
              '${prize?.label ?? 'Um prêmio'} vai a sorteio',
          },
          body: r.candidates.contains(me)
              ? 'Você está no sorteio com $among. O host vai sortear agora.'
              : 'O host vai sortear entre $among.',
          kind: ToastKind.bingo,
        ),
      );
    }
    // A new ball closes any result overlay (not the waiting one).
    if (previous != null &&
        next.draws.length > previous.draws.length &&
        _followed != null) {
      final kind = overlay;
      if (kind != null &&
          kind != ClaimOverlayKind.waiting &&
          kind != ClaimOverlayKind.choose &&
          kind != ClaimOverlayKind.optIn) {
        _followed = null;
      }
    }
    // Any prize that just got its winners: patterns confirmed by the host, or
    // the azarão decided mid-game (last one left standing).
    if (previous != null && next.status == GameStatus.running) {
      final had = {for (final w in previous.winners) w.prizeId};
      for (final p in next.displayPrizes) {
        if (had.contains(p.id)) continue;
        final ws = [
          for (final w in next.winners)
            if (w.prizeId == p.id) w,
        ];
        if (ws.isEmpty) continue;
        // Own win: full overlay. Someone else's: a toast, so the screen
        // stays free for the next ball.
        if (ws.any((w) => w.uid == user?.uid)) {
          delivered = DeliveredPrize(
            prize: p,
            winners: ws,
            next: next.currentPrize,
          );
        } else {
          _toast(
            ToastData(
              title:
                  '${ws.map((w) => _first(w.uid)).join(' e ')} '
                  '${ws.length > 1 ? 'ganharam' : 'ganhou'} ${p.label}',
              body: modalityName(p),
              kind: ToastKind.prize,
            ),
          );
        }
      }
    }
  }

  void dismissDelivered() {
    delivered = null;
    notifyListeners();
  }

  void toggle(int index) {
    final g = game;
    final u = user;
    final c = card;
    if (g == null || u == null || c == null) return;
    if (index == g.template.freeCellIndex || c.cells[index] == null) return;
    // Do not let the player erase stamps while the host checks the claim.
    if (overlay == ClaimOverlayKind.waiting) return;
    marked = {...marked};
    if (!marked.remove(index)) marked.add(index);
    notifyListeners();
    unawaited(_marks.save(g.id, u.uid, marked));
  }

  /// Written reason when BINGO is blocked (R13/R30/R31), else null.
  String? get bingoBlockedReason {
    final g = game;
    final u = user;
    if (g == null || u == null) return null;
    final open = g.openPrizes;
    if (open.isEmpty) return 'Nenhum prêmio em jogo agora';
    final block = _penalty.blockFor(
      uid: u.uid,
      policy: g.settings.claimPenalty,
      history: claims,
      currentDrawIndex: g.draws.length,
    );
    if (block != null) {
      final left = block.drawsLeft;
      return left == null
          ? 'BINGO BLOQUEADO · ${block.reason.toUpperCase()}'
          : 'BINGO BLOQUEADO · VOLTA EM $left ${left == 1 ? 'BOLA' : 'BOLAS'}';
    }
    if (g.status != GameStatus.running) return 'O jogo não está em andamento';
    return null;
  }

  /// Own claims, newest last.
  List<Claim> get myClaims {
    final u = user;
    if (u == null) return const [];
    return [
      for (final c in claims)
        if (c.uid == u.uid) c,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Claim? get followedClaim {
    final id = _followed;
    if (id == null) return null;
    for (final c in claims) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Own claim waiting for a keep/swap answer (shown even if dismissed:
  /// a tied player can be offered a prize later).
  Claim? get choiceClaim {
    for (final c in myClaims.reversed) {
      if (c.status == ClaimStatus.awaitingChoice && !c.answered) return c;
    }
    return null;
  }

  bool choosing = false;

  Future<void> choose(ClaimChoice choice) => _answer(choice, null);

  /// Tie while at the limit: enter the draw ([join]) or skip it.
  Future<void> answerTie({required bool join}) =>
      _answer(join ? ClaimChoice.join : ClaimChoice.skip, null);

  /// Gives up [prize] (the new one or one already held).
  Future<void> release(PrizeId prize) => _answer(null, prize);

  Future<void> _answer(ClaimChoice? choice, PrizeId? release) async {
    final g = game;
    final c = choiceClaim;
    if (g == null || c == null || choosing) return;
    choosing = true;
    _followed = c.id;
    notifyListeners();
    try {
      await _repoRef.chooseClaim(g.id, c.id, choice, releasePrizeId: release);
    } on Object {
      sendError = 'Não deu para enviar sua escolha. Tente de novo.';
    } finally {
      choosing = false;
      notifyListeners();
    }
  }

  ClaimOverlayKind? get overlay {
    if (choiceClaim case final c?) {
      return c.tieOptIn ? ClaimOverlayKind.optIn : ClaimOverlayKind.choose;
    }
    if (_followed == null) return null;
    final c = followedClaim;
    if (c == null) return ClaimOverlayKind.waiting;
    return switch (c.status) {
      ClaimStatus.pending => ClaimOverlayKind.waiting,
      ClaimStatus.tied => ClaimOverlayKind.tieLost,
      ClaimStatus.confirmed => ClaimOverlayKind.valid,
      // Answer sent; the host is applying it.
      ClaimStatus.awaitingChoice => ClaimOverlayKind.waiting,
      ClaimStatus.declined =>
        c.tieOptIn ? ClaimOverlayKind.skipped : ClaimOverlayKind.kept,
      ClaimStatus.rejected => switch (c.verdict) {
        ClaimVerdict.missed => ClaimOverlayKind.missed,
        ClaimVerdict.wrongPattern => ClaimOverlayKind.wrongPattern,
        _ => ClaimOverlayKind.other,
      },
    };
  }

  void dismissOverlay() {
    _followed = null;
    notifyListeners();
  }

  Future<void> callBingo() async {
    final g = game;
    final u = user;
    if (g == null || u == null || sending || bingoBlockedReason != null) return;
    sending = true;
    sendError = null;
    notifyListeners();
    try {
      _followed = await _callBingo(g, u.uid, marked);
    } on GameFailure catch (e) {
      sendError = e.message.isEmpty
          ? 'Não deu para enviar o BINGO.'
          : e.message;
    } on Object {
      sendError = 'Não deu para enviar o BINGO.';
    } finally {
      sending = false;
      notifyListeners();
    }
  }
}
