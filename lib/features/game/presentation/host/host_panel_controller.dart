import 'dart:async';

import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_watch_controller.dart';

/// Host panel (11/12): manual draw, auto-verification of the claims queue,
/// confirm/reject, tie handling and early end.
class HostPanelController extends GameWatchController {
  HostPanelController({
    required super.code,
    required super.repository,
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
    if (claims.any((c) => c.status == ClaimStatus.awaitingChoice)) {
      return 'Aguardando o ganhador escolher qual prêmio fica';
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
    if (g == null || drawBlockedReason != null) return;
    await _run(() => _drawNext(g));
  }

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

  /// tieBreak == allWin: everyone tied wins together. Players already holding
  /// a prize are asked to keep it or swap.
  Future<bool> confirmAll(List<Claim> tied) async {
    if (game == null) return false;
    return await _run(() async {
      final g = await _fresh();
      final free = <Claim>[];
      for (final c in tied) {
        final r = results[c.id];
        if (_heldBy(g, c.uid, except: c.prizeId) != null) {
          await _repoUpdate(
            g,
            _asValid(c, r, c.prizeId, ClaimStatus.awaitingChoice),
          );
        } else {
          await _repoUpdate(
            g,
            _asValid(c, r, c.prizeId, ClaimStatus.confirmed),
          );
          free.add(c);
        }
      }
      if (free.isEmpty) return;
      await _confirmPrize(g, [
        for (final c in free)
          Winner(
            prizeId: c.prizeId,
            uid: c.uid,
            drawIndex: c.drawIndex,
            tieBreak: true,
          ),
      ]);
    });
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
      for (final c in tied) {
        if (c.uid == winner) continue;
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
      final win = tied.firstWhere((c) => c.uid == winner);
      await _award(win, results[win.id], win.prizeId, tieBreak: true);
    });
  }

  // ------------------------------------------------------- keep or swap

  final Set<ClaimId> _choosing = {};

  @override
  void onClaimsChanged(List<Claim> next, {required bool first}) {
    super.onClaimsChanged(next, first: first);
    for (final c in next) {
      if (c.status != ClaimStatus.awaitingChoice || c.choice == null) continue;
      if (!_choosing.add(c.id)) continue;
      unawaited(
        _run(() => _applyChoice(c)).whenComplete(() => _choosing.remove(c.id)),
      );
    }
  }

  Future<Game> _fresh() async {
    final g = game!;
    return await repository.getGame(g.id) ?? g;
  }

  /// The prize [uid] already holds, other than [except].
  static Winner? _heldBy(Game g, UserId uid, {required PrizeId except}) {
    for (final w in g.winners) {
      if (w.uid == uid && w.prizeId != except) return w;
    }
    return null;
  }

  Claim _asValid(Claim c, ClaimResult? r, PrizeId prize, ClaimStatus status) =>
      c.copyWith(
        status: status,
        verdict: r?.verdict ?? ClaimVerdict.valid,
        matched: r?.matched ?? c.matched,
        offerPrizeId: prize == c.prizeId ? null : prize,
      );

  /// Gives [prize] to the player of [c]. Someone who already holds a prize
  /// is asked first (`awaitingChoice`); [_applyChoice] continues from there.
  Future<void> _award(
    Claim c,
    ClaimResult? r,
    PrizeId prize, {
    bool tieBreak = false,
  }) async {
    final g = await _fresh();
    if (_heldBy(g, c.uid, except: prize) != null) {
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
    final held = _heldBy(g, c.uid, except: offer);
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
    if (c.choice == ClaimChoice.swap || held == null) {
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
    if (pool.isEmpty) return _endIfDone();
    final Claim next;
    if (pool.length == 1) {
      next = pool.single;
    } else {
      final uid = await _resolveTie(g, [
        for (final o in pool) o.uid,
      ], prizeId: released);
      next = pool.firstWhere((o) => o.uid == uid);
    }
    await _award(next, results[next.id], released, tieBreak: true);
  }

  /// Ends the game once no prize is open and nobody is still choosing.
  Future<void> _endIfDone() async {
    final g = await _fresh();
    if (g.status != GameStatus.running || g.openPrizes.isNotEmpty) return;
    if (claims.any((c) => c.status == ClaimStatus.awaitingChoice)) return;
    await _endGame(g);
  }

  Future<void> _repoUpdate(Game g, Claim c) => repository.updateClaim(g.id, c);

  /// 11c → abandoned.
  Future<bool> endEarly() async {
    final g = game;
    if (g == null) return false;
    return await _run(() => _endGame(g, status: GameStatus.abandoned));
  }
}
