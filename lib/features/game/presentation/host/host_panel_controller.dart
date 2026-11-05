import 'dart:async';

import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/services/prize_policy_evaluator.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_watch_controller.dart';

/// Host panel (11/12): manual draw, auto-verification of the claims queue,
/// confirm/reject, tie handling and early end.
class HostPanelController extends GameWatchController {
  HostPanelController({
    required super.code,
    required super.repository,
    super.trackUnderdog = true,
    required this._drawNext,
    required VerifyClaim verifyClaim,
    required ResolveClaim resolveClaim,
    required this._resolveTie,
    required this._confirmPrize,
    required this._endGame,
    this._verifier = const BingoVerifier(),
    this._awardUnderdog,
    super.presence,
  }) : _verify = verifyClaim,
       _resolve = resolveClaim;

  /// Azarão by elimination; null in tests or when not registered.
  final AwardUnderdog? _awardUnderdog;
  bool _awarding = false;

  @override
  void onGameChanged(Game? previous, Game next) {
    super.onGameChanged(previous, next);
    _revealIfAutoAbandoned(next);
    final award = _awardUnderdog;
    if (award == null || _awarding) return;
    // Only when a ball was added and the game still has an open azarão.
    if (previous != null && next.draws.length == previous.draws.length) return;
    if (!AwardUnderdog.hasPending(next)) return;
    _awarding = true;
    unawaited(() async {
      try {
        await award(next);
      } on Object {
        // Retried on the next ball; EndGame also settles it at the end.
      } finally {
        _awarding = false;
      }
    }());
  }

  bool _revealing = false;

  /// The game was auto-abandoned for inactivity (by any client): the host
  /// device still holds the seed, so it reveals it for the audit.
  void _revealIfAutoAbandoned(Game g) {
    if (_revealing || g.status != GameStatus.abandoned || g.drawSeed != null) {
      return;
    }
    _revealing = true;
    unawaited(() async {
      try {
        await _endGame(g, status: GameStatus.abandoned);
      } on Object {
        // No seed on this device (another host browser): nothing to reveal.
      }
    }());
  }

  final DrawNext _drawNext;
  final VerifyClaim _verify;
  final ResolveClaim _resolve;
  final ResolveTie _resolveTie;
  final ConfirmPrize _confirmPrize;
  final EndGame _endGame;
  final BingoVerifier _verifier;

  /// Auto-verification results keyed by claim id (local to the host).
  final Map<ClaimId, ClaimResult> results = {};
  final Set<ClaimId> _verifying = {};

  bool busy = false;
  String? actionError;

  /// Marks the host online in RTDB (players see 09d when this drops).
  @override
  Future<void> start() async {
    await super.start();
    final g = game;
    final presence = presenceRepository;
    if (g == null || presence == null) return;
    try {
      await presence.announceHost(g.id);
    } on Object {
      // Presence is best-effort; the panel keeps working without it.
    }
  }

  @override
  void notifyListeners() {
    _verifyPending();
    super.notifyListeners();
  }

  void _verifyPending() {
    final g = game;
    if (g == null) return;
    for (final c in claims) {
      if (c.status != ClaimStatus.pending) continue;
      if (results.containsKey(c.id) || _verifying.contains(c.id)) continue;
      _verifying.add(c.id);
      unawaited(_runVerify(g, c));
    }
  }

  Future<void> _runVerify(Game g, Claim c) async {
    try {
      results[c.id] = await _verify(g, c, claims);
    } on Object catch (e) {
      results[c.id] = ClaimResult(
        verdict: ClaimVerdict.tampered,
        reason: 'Falha ao verificar: $e',
      );
    } finally {
      _verifying.remove(c.id);
      super.notifyListeners();
    }
  }

  /// Claim with the verdict applied (for tie detection and display).
  Claim withResult(Claim c) {
    final r = results[c.id];
    return r == null ? c : c.copyWith(verdict: r.verdict, matched: r.matched);
  }

  /// R28: SORTEAR blocked while there is a pending claim for this draw.
  String? get drawBlockedReason {
    final g = game;
    if (g == null) return 'Carregando…';
    if (g.status != GameStatus.running) return 'O jogo não está em andamento';
    if (g.draws.length >= g.template.pool.length) {
      return 'Todas as bolas já saíram';
    }
    if (pendingClaims.isNotEmpty) {
      return 'Confira os pedidos de BINGO antes de sortear a próxima bola';
    }
    if (g.raffle case final r? when r.winner == null) {
      final label = g.prizeById(r.prizeId)?.label ?? 'prêmio';
      return 'Faça o sorteio de $label antes de seguir';
    }
    if (claims.any(
      (c) => c.status == ClaimStatus.awaitingChoice && c.tieOptIn,
    )) {
      return 'Aguardando quem já está no limite decidir se entra no desempate';
    }
    if (claims.any((c) => c.status == ClaimStatus.awaitingChoice)) {
      return 'Aguardando o ganhador escolher quais prêmios ficam';
    }
    return null;
  }

  /// 2+ valid claims for the current prize at the same drawIndex (12a).
  List<Claim> tiedFor(Claim claim) {
    final g = game;
    if (g == null) return const [];
    final candidates = [
      for (final c in claims)
        if (c.prizeId == claim.prizeId) withResult(c),
    ];
    final tied = _verifier.tiedValidClaims(candidates);
    return tied.any((c) => c.id == claim.id) ? tied : const [];
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    actionError = null;
    super.notifyListeners();
    try {
      await action();
      return true;
    } on GameFailure catch (e) {
      actionError = e.message.isEmpty ? _failureText(e.code) : e.message;
      return false;
    } on Object catch (e) {
      actionError = 'Algo deu errado: $e';
      return false;
    } finally {
      busy = false;
      super.notifyListeners();
    }
  }

  String _failureText(GameFailureCode code) => switch (code) {
    GameFailureCode.pendingClaims => 'Há pedidos de BINGO pendentes.',
    GameFailureCode.notHost => 'Seed do sorteio ausente neste dispositivo.',
    GameFailureCode.finished => 'A partida já terminou.',
    _ => 'Não foi possível concluir a ação.',
  };

  Future<void> draw() async {
    final g = game;
    if (g == null || drawBlockedReason != null || busy) return;
    drawing = true;
    // Short minimum so the press always gets visible feedback and fast
    // double taps cannot queue a second ball.
    await _run(
      () => Future.wait([
        _drawNext(g),
        Future<void>.delayed(const Duration(milliseconds: 450)),
      ]),
    );
    drawing = false;
    super.notifyListeners();
  }

  /// True while SORTEAR is running (button shows a loader).
  bool drawing = false;

  Future<bool> reject(Claim claim) async {
    final g = game;
    final r = results[claim.id];
    if (g == null) return false;
    return await _run(
      () => _resolve(
        g,
        claim,
        r ?? const ClaimResult(verdict: ClaimVerdict.missed),
        accept: false,
      ),
    );
  }

  /// Single valid claim: accept + confirm prize (or ask to keep/swap).
  Future<bool> confirmSingle(Claim claim) async {
    final r = results[claim.id];
    if (game == null || r == null) return false;
    return await _run(() => _award(claim, r, claim.prizeId));
  }

  /// 12b: deterministic draw among the tied players.
  Future<UserId?> drawTie(List<Claim> tied) async {
    final g = game;
    if (g == null) return null;
    UserId? winner;
    await _run(() async {
      winner = await _resolveTie(g, [
        for (final c in tied) c.uid,
      ], prizeId: tied.first.prizeId);
    });
    return winner;
  }

  /// 12b: confirms the tie winner; other tied claims become `tied` and stay
  /// in line in case the winner keeps a prize they already had.
  Future<bool> confirmTie(List<Claim> tied, UserId winner) async {
    if (game == null) return false;
    return await _run(() async {
      final g = await _fresh();
      final win = tied.firstWhere((c) => c.uid == winner);
      await _parkOthers(g, win);
      await _award(win, results[win.id], win.prizeId, tieBreak: true);
    });
  }

  /// Every other claim still pending in the same tie as [win] becomes
  /// `tied` (in line in case the winner gives the prize up).
  Future<void> _parkOthers(Game g, Claim win) async {
    for (final c in claims) {
      if (c.id == win.id ||
          c.prizeId != win.prizeId ||
          c.drawIndex != win.drawIndex ||
          c.status != ClaimStatus.pending) {
        continue;
      }
      final r = results[c.id];
      await _repoUpdate(
        g,
        c.copyWith(
          status: ClaimStatus.tied,
          verdict: r?.verdict ?? ClaimVerdict.valid,
          matched: r?.matched ?? c.matched,
        ),
      );
    }
  }

  // ------------------------------------------------------- keep or swap

  final Set<ClaimId> _choosing = {};

  @override
  void onClaimsChanged(List<Claim> next, {required bool first}) {
    super.onClaimsChanged(next, first: first);
    for (final c in next) {
      if (c.status != ClaimStatus.awaitingChoice || !c.answered) continue;
      if (!_choosing.add(c.id)) continue;
      unawaited(
        _run(() => c.tieOptIn ? _applyOptIn(c) : _applyChoice(c))
            .whenComplete(() => _choosing.remove(c.id)),
      );
    }
  }

  Future<Game> _fresh() async {
    final g = game!;
    return await repository.getGame(g.id) ?? g;
  }

  static const _policy = PrizePolicyEvaluator();

  /// Winning [prize] would exceed the room's limit for [uid] (count or the
  /// "who won X may compete for Y" matrix), so they must give one up.
  static bool _needsChoice(Game g, UserId uid, PrizeId prize) => _policy
      .releaseOptions(
        held: _policy.heldBy(uid, g.winners, except: prize),
        offer: prize,
        policy: g.prizePolicy,
      )
      .isNotEmpty;

  Claim _asValid(Claim c, ClaimResult? r, PrizeId prize, ClaimStatus status) =>
      c.copyWith(
        status: status,
        verdict: r?.verdict ?? ClaimVerdict.valid,
        matched: r?.matched ?? c.matched,
        offerPrizeId: prize == c.prizeId ? null : prize,
        // From here on an awaitingChoice is about which prizes to keep.
        tieOptIn: false,
      );

  /// Gives [prize] to the player of [c]. When that would exceed the room's
  /// limit they are asked first (`awaitingChoice`); [_applyChoice] continues.
  Future<void> _award(
    Claim c,
    ClaimResult? r,
    PrizeId prize, {
    bool tieBreak = false,
  }) async {
    final g = await _fresh();
    if (_needsChoice(g, c.uid, prize)) {
      await _repoUpdate(g, _asValid(c, r, prize, ClaimStatus.awaitingChoice));
      return;
    }
    await _repoUpdate(g, _asValid(c, r, prize, ClaimStatus.confirmed));
    await _confirmPrize(g, [
      Winner(
        prizeId: prize,
        uid: c.uid,
        drawIndex: c.drawIndex,
        tieBreak: tieBreak,
      ),
    ]);
  }

  /// Applies the player's answer. The prize they let go goes to the others
  /// tied with them: one other takes it, 3+ draw among themselves. Without a
  /// tie it goes back into play.
  Future<void> _applyChoice(Claim c) async {
    final g = await _fresh();
    final offer = c.offerPrizeId ?? c.prizeId;
    final heldIds = _policy.heldBy(c.uid, g.winners, except: offer);
    // The prize given up: explicit answer, or the legacy keep/swap.
    var release = c.releasePrizeId;
    if (release == null && c.choice == ClaimChoice.swap) {
      final options = _policy.releaseOptions(
        held: heldIds,
        offer: offer,
        policy: g.prizePolicy,
      );
      release = options.firstWhere((p) => p != offer, orElse: () => offer);
      if (release == offer && heldIds.isNotEmpty) release = heldIds.first;
    }
    release ??= offer;
    Winner? held;
    if (release != offer) {
      for (final w in g.winners) {
        if (w.uid == c.uid && w.prizeId == release) {
          held = w;
          break;
        }
      }
    }
    final pool = [
      for (final o in claims)
        if (o.id != c.id &&
            o.prizeId == c.prizeId &&
            o.status == ClaimStatus.tied)
          o,
    ];
    final tie =
        pool.isNotEmpty || g.winnersOf(c.prizeId).any((w) => w.tieBreak);
    PrizeId released;
    if (release != offer) {
      await repository.setWinners(g.id, [
        for (final w in g.winners)
          if (w != held) w,
        Winner(
          prizeId: offer,
          uid: c.uid,
          drawIndex: c.drawIndex,
          tieBreak: tie,
        ),
      ]);
      await _repoUpdate(g, c.copyWith(status: ClaimStatus.confirmed));
      if (held == null) return _endIfDone();
      released = held.prizeId;
    } else {
      await _repoUpdate(g, c.copyWith(status: ClaimStatus.declined));
      released = offer;
    }
    if (pool.isEmpty) return _releaseFree(released, releasedBy: c.uid);
    if (pool.length == 1) {
      final next = pool.single;
      await _award(next, results[next.id], released, tieBreak: true);
      return;
    }
    // 2+ others bingoed with them: drawn on screen among those.
    await repository.setRaffle(
      g.id,
      Raffle(
        prizeId: released,
        candidates: [for (final o in pool) o.uid],
        kind: RaffleKind.released,
        releasedBy: c.uid,
      ),
    );
  }

  /// A prize nobody tied for was given up: back into play, or drawn among
  /// everyone still under the limit (room setting). The azarão is always
  /// drawn, since its race is already over.
  Future<void> _releaseFree(PrizeId prizeId, {UserId? releasedBy}) async {
    final g = await _fresh();
    final prize = g.prizeById(prizeId);
    if (prize == null) return _endIfDone();
    final underdog = prize.pattern == PatternKind.underdog;
    if (g.settings.overLimit == OverLimitRule.raffle || underdog) {
      final candidates = [
        for (final p in players)
          if (p.uid != releasedBy &&
              _policy.isEligible(
                uid: p.uid,
                target: prize,
                winners: g.winners,
                policy: g.prizePolicy,
              ))
            p.uid,
      ];
      if (candidates.isNotEmpty) {
        await repository.setRaffle(
          g.id,
          Raffle(
            prizeId: prizeId,
            candidates: candidates,
            kind: RaffleKind.released,
            releasedBy: releasedBy,
          ),
        );
        return;
      }
    }
    // Back into play: it has no winner now, so it is open again.
    await _endIfDone();
  }

  // ------------------------------------------------------------ raffle

  /// Host presses SORTEAR on a pending [Raffle]: seeded, auditable pick
  /// (same as the tiebreak), shown on the stream, then the prize goes out.
  Future<bool> runRaffle() async {
    final r = game?.raffle;
    if (r == null || r.winner != null) return false;
    return _run(() async {
      final g = await _fresh();
      final uid = await _resolveTie(g, r.candidates, prizeId: r.prizeId);
      await repository.setRaffle(g.id, r.copyWith(winner: uid));
      // One of those who bingoed with the releaser: their claim carries the
      // prize (and the limit check, if they hit it).
      for (final o in claims) {
        if (o.uid == uid && o.status == ClaimStatus.tied) {
          await _award(o, results[o.id], r.prizeId, tieBreak: true);
          return;
        }
      }
      final w = Winner(
        prizeId: r.prizeId,
        uid: uid,
        drawIndex: g.draws.length,
        tieBreak: true,
      );
      if (g.prizes.any((p) => p.id == r.prizeId)) {
        await _confirmPrize(g, [w]);
      } else {
        await repository.awardPrize(g.id, winners: [w]);
        await _endIfDone();
      }
    });
  }

  // ------------------------------------------------- tie with opt-in

  /// Before a tie draw, tied players already at the limit are asked whether
  /// they join it or skip it (skipping leaves it to the others).
  Future<void> askTieOptIns(List<Claim> tied) async {
    await _run(() async {
      final g = await _fresh();
      for (final c in tied) {
        final now = claims.firstWhere((o) => o.id == c.id, orElse: () => c);
        if (now.tieOptIn || now.status != ClaimStatus.pending) continue;
        if (!_needsChoice(g, c.uid, c.prizeId)) continue;
        await _repoUpdate(
          g,
          _asValid(
            now,
            results[c.id],
            c.prizeId,
            ClaimStatus.awaitingChoice,
          ).copyWith(tieOptIn: true),
        );
      }
    });
  }

  /// A tie right now: who is still in it, who skipped, and whether someone
  /// still has to answer.
  TieState tieState(List<Claim> tied) {
    final ids = {for (final c in tied) c.id};
    final now = [
      for (final c in claims)
        if (ids.contains(c.id)) withResult(c),
    ];
    final live = [
      for (final c in now)
        if (c.status == ClaimStatus.pending) c,
    ];
    final g = game;
    final keep = g == null
        ? {for (final c in live) c.uid}
        : tieContenders(
            [for (final c in live) c.uid],
            g.winners,
            g.settings.tieBreak,
          ).toSet();
    return TieState(
      live: live,
      contenders: [
        for (final c in live)
          if (keep.contains(c.uid)) c,
      ],
      skipped: [
        for (final c in now)
          if (c.status == ClaimStatus.declined && c.tieOptIn) c,
      ],
      waiting: now.any(
        (c) => c.status == ClaimStatus.awaitingChoice && c.tieOptIn,
      ),
    );
  }

  /// Applies a join/skip answer: join puts the claim back in the tie.
  Future<void> _applyOptIn(Claim c) async {
    final g = await _fresh();
    await _repoUpdate(
      g,
      c.choice == ClaimChoice.skip
          ? c.copyWith(status: ClaimStatus.declined)
          : c.copyWith(status: ClaimStatus.pending, choice: null),
    );
  }

  /// Only one player left after the others skipped: they take the prize.
  Future<bool> awardSoleTied(Claim c) => _run(() async {
    await _parkOthers(await _fresh(), c);
    await _award(c, results[c.id], c.prizeId, tieBreak: true);
  });

  /// Everyone in the tie skipped: the prize follows the room rule.
  Future<bool> releaseSkippedTie(PrizeId prize) =>
      _run(() => _releaseFree(prize));

  /// Ends the game once no prize is open and nobody is still choosing.
  Future<void> _endIfDone() async {
    final g = await _fresh();
    if (g.status != GameStatus.running || g.openPrizes.isNotEmpty) return;
    if (claims.any((c) => c.status == ClaimStatus.awaitingChoice)) return;
    await _endGame(g);
  }

  Future<void> _repoUpdate(Game g, Claim c) => repository.updateClaim(g.id, c);

  /// Why the host cannot end the game early right now (null = allowed).
  String? get endBlockedReason {
    final g = game;
    if (g == null) return 'Carregando…';
    if (isFinished) return 'A partida já terminou';
    if (pendingClaims.isNotEmpty) {
      return 'Confira os pedidos de BINGO antes de encerrar o jogo';
    }
    if (claims.any((c) => c.status == ClaimStatus.awaitingChoice)) {
      return 'Aguarde o ganhador escolher qual prêmio fica antes de encerrar';
    }
    if (g.raffle case final r? when r.winner == null) {
      return 'Faça o sorteio pendente antes de encerrar';
    }
    return null;
  }

  /// 11c → abandoned. Blocked while claims wait (see [endBlockedReason]).
  Future<bool> endEarly() async {
    final g = game;
    if (g == null) return false;
    final blocked = endBlockedReason;
    if (blocked != null) {
      actionError = blocked;
      super.notifyListeners();
      return false;
    }
    return await _run(() => _endGame(g, status: GameStatus.abandoned));
  }
}

/// A tie while tied players at the limit decide whether to join.
final class TieState {
  const TieState({
    required this.live,
    required this.contenders,
    required this.skipped,
    required this.waiting,
  });

  /// Still in the tie (pending claims).
  final List<Claim> live;

  /// Of [live], who actually competes: everyone on a plain draw, only
  /// those with the fewest prizes on [TieBreakRule.fewestPrizes].
  final List<Claim> contenders;

  /// Were at the limit and chose to skip.
  final List<Claim> skipped;

  /// Someone has not answered yet.
  final bool waiting;
}
