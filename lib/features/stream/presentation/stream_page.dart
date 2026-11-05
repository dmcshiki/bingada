import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/data/access_checker.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';
import 'package:tokingo/features/stream/presentation/stream_controller.dart';
import 'package:tokingo/features/stream/presentation/stream_end.dart';
import 'package:tokingo/features/stream/presentation/stream_fx.dart';
import 'package:tokingo/features/stream/presentation/stream_tie_reveal.dart';

/// 13 – streamer screen. Read-only composition: there is no admin control
/// here, not even hidden (R6, §3.2). No ball count (R23), no QR (R24).
class StreamPage extends StatefulWidget {
  const StreamPage({
    required this.code,
    super.key,
    this.chroma = false,
    this.compact = false,
  });

  final RoomCode code;

  /// `?chroma=1`: green background for OBS keying.
  final bool chroma;

  /// `?compact=1`: small OBS source with only the current ball, the last
  /// balls and the footer (no pool board, no background shapes).
  final bool compact;

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  late final StreamController _c;
  ItemId? _lastBall;

  static const _chromaGreen = Color(0xFF00B140);

  @override
  void initState() {
    super.initState();
    _c = StreamController(
      code: widget.code,
      repository: sl<GameRepository>(),
      verifyClaim: sl.isRegistered<VerifyClaim>() ? sl<VerifyClaim>() : null,
      verifier: sl.isRegistered<BingoVerifier>()
          ? sl<BingoVerifier>()
          : const BingoVerifier(),
    )..addListener(_onChange);
    unawaited(_c.start());
  }

  void _onChange() {
    final ball = _c.game?.currentBall;
    if (!mounted || ball == null || ball == _lastBall) return;
    final first = _lastBall == null;
    _lastBall = ball;
    if (!first) {
      unawaited(
        announce(context, 'Nova bola: ${_c.game!.template.ballText(ball)}'),
      );
    }
  }

  @override
  void dispose() {
    _c
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  /// Spectators follow the same access rule as players (the Firestore
  /// rules enforce it; this only explains the refusal).
  bool _denied(Game? g) {
    if (g == null) {
      final e = _c.error;
      return e is GameFailure && e.code == GameFailureCode.accessDenied;
    }
    final u = sl<AuthRepository>().currentUser;
    if (u == null) return true;
    return u.uid != g.hostUid &&
        !_c.players.any((p) => p.uid == u.uid) &&
        !accessAllows(g.access, u.email);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final bg = widget.chroma ? _chromaGreen : AppColors.navy;
      final g = _c.game;
      if (_denied(g)) {
        return Scaffold(
          backgroundColor: bg,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Você não tem acesso a esta sala. Só assiste quem também '
                'poderia entrar nela.',
                textAlign: TextAlign.center,
                style: AppText.body(22, color: AppColors.white),
              ),
            ),
          ),
        );
      }
      if (g == null) {
        return Scaffold(
          backgroundColor: bg,
          body: Center(
            child: _c.loading
                ? const TokenLoader(
                    size: 140,
                    color: AppColors.white,
                    dotColor: AppColors.navy,
                    label: 'Conectando à transmissão…',
                    labelColor: AppColors.white,
                  )
                : Text(
                    'Sala não encontrada.',
                    style: AppText.body(22, color: AppColors.white),
                  ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            if (!widget.chroma && !widget.compact) ...const [
              Positioned(
                right: -200,
                top: -260,
                child: BlobShape(size: 620, color: AppColors.deepBlue),
              ),
              Positioned(
                left: -160,
                bottom: -300,
                child: BlobShape(size: 560, color: AppColors.graphite),
              ),
            ],
            Positioned.fill(
              child: SafeArea(
                child: _c.isFinished
                    ? StreamEnd(
                        game: g,
                        players: _c.players,
                        claims: _c.claims,
                        chroma: widget.chroma,
                      )
                    : _StreamBoard(
                        game: g,
                        players: _c.players,
                        underdogAlive: _c.underdogAlive,
                        compact: widget.compact,
                      ),
              ),
            ),
            if (!_c.isFinished)
              if (_c.overlay case final o?)
                _StreamOverlayView(overlay: o, game: g, players: _c.players),
          ],
        ),
      );
    },
  );
}

class _StreamBoard extends StatelessWidget {
  const _StreamBoard({
    required this.game,
    required this.players,
    this.compact = false,
    this.underdogAlive,
  });

  final Game game;
  final List<Player> players;
  final List<UserId>? underdogAlive;
  final bool compact;

  /// Design canvas of the wide layout; it is scaled to fit the viewport.
  static const _canvas = Size(1600, 900);

  /// Below this width (phones) the stream falls back to a scrolling column.
  static const _minWideWidth = 700.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wordmark = Text(
        'tokingo',
        style: AppText.display(30, color: AppColors.white),
      );
      if (compact || box.maxWidth < _minWideWidth) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[wordmark, const SizedBox(height: 16)],
              _ball(220),
              const SizedBox(height: 24),
              _last(),
              const SizedBox(height: 24),
              _StreamFooter(game: game, scale: 1),
            ],
          ),
        );
      }
      // Lay out at the design size (stretched to the viewport's aspect ratio)
      // and scale the whole thing down/up to fit both width and height.
      final s = math.min(
        box.maxWidth / _canvas.width,
        box.maxHeight / _canvas.height,
      );
      final logical = Size(box.maxWidth / s, box.maxHeight / s);
      return FittedBox(
        child: SizedBox.fromSize(
          size: logical,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 40, 48, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                wordmark,
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ball(400)),
                      const SizedBox(width: 48),
                      SizedBox(
                        width: 480,
                        child: SingleChildScrollView(child: _last()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _StreamFooter(game: game, scale: 1),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _ball(double size) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SplitTitle('bola', 'atual', size: 22, color: AppColors.white),
      const SizedBox(height: 28),
      BallToken(template: game.template, ball: game.currentBall, size: size),
    ],
  );

  Widget _last() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _LastBalls(game: game, scale: 1),
      const SizedBox(height: 28),
      _StreamPrizes(
        game: game,
        players: players,
        scale: 1,
        underdogAlive: underdogAlive,
      ),
    ],
  );
}

class _LastBalls extends StatelessWidget {
  const _LastBalls({required this.game, required this.scale});

  final Game game;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final recent = game.draws.reversed.take(3).toList();
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ÚLTIMAS BOLAS',
          style: AppText.body(
            14 * scale,
            weight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: .84 * scale,
          ),
        ),
        SizedBox(height: 12 * scale),
        if (recent.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 18 * scale,
              vertical: 16 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(18 * scale),
            ),
            child: Row(
              children: [
                LoadingDots(
                  dotSize: 10 * scale,
                  semanticLabel: 'Aguardando a primeira bola',
                ),
                SizedBox(width: 14 * scale),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      'aguardando a primeira bola',
                      style: AppText.body(17 * scale, color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Semantics(
            label:
                'Últimas bolas: ${recent.map(game.template.ballText).join(', ')}',
            child: ExcludeSemantics(
              child: Wrap(
                spacing: 14 * scale,
                runSpacing: 10 * scale,
                children: [
                  for (final (i, id) in recent.indexed)
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: reduce ? 150 : 380),
                      transitionBuilder: (child, anim) => reduce
                          ? FadeTransition(opacity: anim, child: child)
                          : ScaleTransition(
                              scale: anim,
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                      child: _ballChip(id, (i == 0 ? 92 : 72) * scale),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

extension on _LastBalls {
  Widget _ballChip(ItemId id, double size) {
    final color = game.template.columnColor(id.column);
    return SizedBox(
      key: ValueKey(id.value),
      width: size * 1.1,
      height: size * 1.1,
      child: Center(
        child: TokenBox(
          size: size,
          color: color,
          child: Padding(
            padding: EdgeInsets.all(size * .1),
            child: FittedBox(
              child: Text(
                game.template.ballShort(id),
                style: AppText.display(
                  size * .32,
                  color: AppColors.onColor(color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreamFooter extends StatelessWidget {
  const _StreamFooter({required this.game, required this.scale});

  final Game game;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final closed = game.status != GameStatus.lobby;
    return Container(
      constraints: BoxConstraints(minHeight: 72 * scale),
      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(22 * scale),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 8,
        children: [
          Text.rich(
            TextSpan(
              style: AppText.body(20 * scale, color: AppColors.white),
              children: [
                const TextSpan(text: 'Sala '),
                TextSpan(
                  text: game.roomCode.value,
                  style: AppText.display(
                    20 * scale,
                    color: AppColors.white,
                  ).copyWith(letterSpacing: 2 * scale),
                ),
                if (closed) ...const [
                  TextSpan(text: ' · '),
                  TextSpan(
                    text: 'fechada',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ': jogo em andamento'),
                ],
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              style: AppText.body(18 * scale, color: AppColors.white),
              children: [
                const TextSpan(text: 'Valendo: '),
                TextSpan(
                  text: openPrizesText(game),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      ' · ${game.playerCount} jogador${game.playerCount == 1 ? '' : 'es'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamOverlayView extends StatelessWidget {
  const _StreamOverlayView({
    required this.overlay,
    required this.game,
    required this.players,
  });

  final StreamOverlay overlay;
  final Game game;
  final List<Player> players;

  @override
  Widget build(BuildContext context) => switch (overlay) {
    CheckingOverlay(:final claim) => _OneOverlay(
      kicker: 'BINGO!',
      name: playerName(players, claim.uid),
      uid: claim.uid,
      badge: 'O HOST ESTÁ CONFERINDO…',
      badgeBg: AppColors.light,
      badgeFg: AppColors.navy,
      text: '${_valendo(game.currentPrize)} Segura o carimbo aí.',
    ),
    ValidOverlay(:final claim, :final prize) => _OneOverlay(
      key: ValueKey('valid-${claim.id.value}'),
      kicker: 'BINGO!',
      name: playerName(players, claim.uid),
      uid: claim.uid,
      badge: [
        'VÁLIDO',
        if (prize != null) modalityName(prize).toUpperCase(),
        ballOrdinal(claim.drawIndex).toUpperCase(),
      ].join(' · '),
      badgeBg: AppColors.greenDark,
      badgeFg: AppColors.white,
      text: 'Levou a ${prize?.label ?? ''}. ${_next(game)}',
      celebrate: true,
    ),
    MissedOverlay(:final claim, :final wrongPattern) => _OneOverlay(
      key: ValueKey('missed-${claim.id.value}'),
      kicker: 'BINGO?',
      name: playerName(players, claim.uid),
      uid: claim.uid,
      badge: wrongPattern ? 'PADRÃO ERRADO' : 'COMEU BOLA',
      badgeBg: AppColors.purple,
      badgeFg: AppColors.white,
      text:
          '${wrongPattern ? 'O desenho marcado não fecha o prêmio que está valendo.' : 'Marcou bola que ainda não saiu.'} '
          'O jogo continua valendo a ${game.currentPrize?.label ?? ''}.',
      shake: true,
    ),
    ChoosingOverlay(:final claim, :final offered) => _OneOverlay(
      key: ValueKey('choosing-${claim.id.value}'),
      kicker: 'BINGO!',
      name: playerName(players, claim.uid),
      uid: claim.uid,
      badge: claim.tieOptIn ? 'EMPATE · DECIDINDO…' : 'ESTÁ ESCOLHENDO…',
      badgeBg: AppColors.light,
      badgeFg: AppColors.navy,
      text: claim.tieOptIn
          ? '${playerName(players, claim.uid)} empatou, mas já está no limite '
                'de prêmios: está decidindo se entra no sorteio ou deixa para '
                'quem bingou junto.'
          : '${playerName(players, claim.uid)} passou do limite de prêmios e '
                'está escolhendo com quais fica'
                '${offered == null ? '' : ' (acabou de ganhar ${offered.label})'}.',
    ),
    RaffleOverlay(:final raffle) => _TieOverlay(
      key: ValueKey(
        'raffle-${raffle.prizeId.value}-${raffle.candidates.length}',
      ),
      game: game,
      players: players,
      tied: raffle.candidates,
      prize: game.prizeById(raffle.prizeId),
      winners: raffle.winner == null ? null : {raffle.winner!},
      drawIndex: game.draws.length,
      headline: raffle.kind == RaffleKind.underdogTie
          ? 'EMPATE NO AZARÃO · SAÍRAM NA MESMA BOLA'
          : 'SORTEIO · '
                '${game.prizeById(raffle.prizeId)?.label.toUpperCase() ?? ''}',
    ),
    ChoiceOverlay(:final claim, :final offered, :final swapped) => _OneOverlay(
      key: ValueKey('choice-${claim.id.value}'),
      kicker: swapped ? 'TROCOU!' : 'FICOU COM O SEU!',
      name: playerName(players, claim.uid),
      uid: claim.uid,
      badge: swapped
          ? 'LEVOU A ${offered?.label.toUpperCase() ?? ''}'
          : 'MANTEVE O PRÊMIO',
      badgeBg: swapped ? AppColors.greenDark : AppColors.pink,
      badgeFg: swapped ? AppColors.white : AppColors.navy,
      text: swapped
          ? 'Trocou pelo novo prêmio. ${_next(game)}'
          : 'Preferiu o prêmio que já tinha. '
                '${offered == null ? '' : 'A ${offered.label} segue no jogo. '}'
                '${_next(game)}',
      celebrate: swapped,
    ),
    UnderdogOverlay(:final prize, :final winners) => _OneOverlay(
      key: ValueKey('underdog-${prize.id.value}'),
      celebrate: true,
      kicker: 'AZARÃO!',
      name: winners.map((w) => playerName(players, w.uid)).join(' e '),
      uid: winners.first.uid,
      badge: winners.first.tieBreak ? 'VENCEU O DESEMPATE' : 'ÚLTIMO A SOBRAR',
      badgeBg: AppColors.pink,
      badgeFg: AppColors.navy,
      text:
          'Resistiu ${winners.first.drawIndex} bolas sem nenhum número na cartela. '
          'Levou o ${prize.label}. O jogo continua valendo a '
          '${game.currentPrize?.label ?? ''}.',
    ),
    TieOverlay(:final tied, :final prize, :final winners) => _TieOverlay(
      key: ValueKey('tie-${prize?.id.value}-${tied.first.drawIndex}'),
      game: game,
      players: players,
      tied: tied.map((c) => c.uid).toList(),
      prize: prize,
      winners: winners,
      drawIndex: tied.first.drawIndex,
    ),
  };

  static String _valendo(Prize? p) =>
      p == null ? '' : '${modalityName(p)} · valendo a ${p.label}.';

  static String _next(Game g) {
    final n = g.currentPrize;
    return n == null
        ? 'Fim de jogo!'
        : 'Agora vale: ${n.label} · ${modalityName(n)}';
  }
}

class _OneOverlay extends StatelessWidget {
  const _OneOverlay({
    super.key,
    this.celebrate = false,
    this.shake = false,
    required this.kicker,
    required this.name,
    required this.uid,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.text,
  });

  final String kicker;
  final String name;
  final UserId uid;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final String text;

  /// Winner celebration: token burst behind the card.
  final bool celebrate;

  /// Failed claim: a short "no" wobble on entry.
  final bool shake;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final info = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kicker,
          style: AppText.body(18, weight: FontWeight.w700, letterSpacing: 1.08),
        ),
        const SizedBox(height: 14),
        Text(name, style: AppText.display(48, color: AppColors.navy)),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: EllipsisText(
              badge,
              style: AppText.display(26, color: badgeFg),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(text, style: AppText.body(20, height: 1.4)),
      ],
    );
    Widget card = DialogCard(
      semanticLabel: '$kicker $name: $badge',
      maxWidth: 920,
      padding: const EdgeInsets.all(48),
      child: wide
          ? Row(
              children: [
                NameToken(name: name, uid: uid, size: 200),
                const SizedBox(width: 40),
                Expanded(child: info),
              ],
            )
          : Column(
              children: [
                NameToken(name: name, uid: uid, size: 120),
                const SizedBox(height: 20),
                info,
              ],
            ),
    );
    final shaker = shake && !reduce;
    card = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: shaker ? 700 : 1),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(
          shaker ? math.sin(t * math.pi * 6) * 18 * (1 - t) : 0,
          0,
        ),
        child: child,
      ),
      child: card,
    );
    return ScrimOverlay(
      color: const Color(0xD1142840),
      child: Semantics(
        liveRegion: true,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (celebrate)
              const Positioned.fill(child: TokenBurst(radius: 520, count: 40)),
            PopIn(child: card),
          ],
        ),
      ),
    );
  }
}

class _TieOverlay extends StatefulWidget {
  const _TieOverlay({
    super.key,
    required this.game,
    required this.players,
    required this.tied,
    required this.prize,
    required this.winners,
    required this.drawIndex,
    this.headline,
  });

  /// Replaces the "EMPATE" headline (draw of a prize someone gave up).
  final String? headline;

  final Game game;
  final List<Player> players;
  final List<UserId> tied;
  final Prize? prize;
  final Set<UserId>? winners;
  final int drawIndex;

  @override
  State<_TieOverlay> createState() => _TieOverlayState();
}

class _TieOverlayState extends State<_TieOverlay> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final prize = widget.prize;
    final w = widget.winners;
    final done = w != null && _revealed;
    final next = widget.game.currentPrize;
    final names = [
      for (final uid in widget.tied)
        if (w?.contains(uid) ?? false) playerName(widget.players, uid),
    ].join(' e ');
    return ScrimOverlay(
      color: const Color(0xE0142840),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  widget.headline ??
                      'EMPATE · ${prize?.label.toUpperCase() ?? ''} · '
                          '${prize == null ? '' : modalityName(prize).toUpperCase()} · NA MESMA BOLA',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    18,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: 1.08,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: done
                  ? PopIn(
                      key: const ValueKey('done'),
                      child: Text(
                        '$names levou!',
                        textAlign: TextAlign.center,
                        style: AppText.display(56, color: AppColors.white),
                      ),
                    )
                  : EllipsisText(
                      key: const ValueKey('drawing'),
                      widget.headline == null
                          ? 'Sorteando o desempate…'
                          : 'Aguardando o sorteio…',
                      textAlign: TextAlign.center,
                      style: AppText.display(56, color: AppColors.white),
                    ),
            ),
            const SizedBox(height: 28),
            TieReveal(
              tied: widget.tied,
              players: widget.players,
              winners: w,
              how: [
                if (prize != null) modalityName(prize),
                ballOrdinal(widget.drawIndex),
              ].join(' · '),
              winnerTag: 'LEVOU A ${prize?.label.toUpperCase() ?? ''}',
              onRevealed: () {
                if (mounted) setState(() => _revealed = true);
              },
            ),
            const SizedBox(height: 28),
            Text(
              done
                  ? (next == null
                        ? 'Fim de jogo!'
                        : 'Agora vale: ${next.label} · ${modalityName(next)}')
                  : 'Ninguém escolhe, nem o host: o sistema sorteia.',
              textAlign: TextAlign.center,
              style: AppText.body(20, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prize board of the stream: azarão first, pattern prizes (open together),
/// full card last. Shows who took each prize as soon as it is confirmed.
class _StreamPrizes extends StatelessWidget {
  const _StreamPrizes({
    required this.game,
    required this.players,
    required this.scale,
    this.underdogAlive,
  });

  final Game game;
  final List<UserId>? underdogAlive;
  final List<Player> players;
  final double scale;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'PRÊMIOS',
        style: AppText.body(
          14 * scale,
          weight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: .84 * scale,
        ),
      ),
      SizedBox(height: 12 * scale),
      for (final p in game.displayPrizes) _row(p),
    ],
  );

  Widget _row(Prize p) {
    final st = prizeStatus(game, p);
    final (tag, bg, fg) = switch (st) {
      PrizeStatus.won => (
        '🏆 ${winnerNames(game, p, players)}',
        AppColors.green,
        AppColors.white,
      ),
      PrizeStatus.open => ('VALENDO', AppColors.cyan, AppColors.inkOnLight),
      PrizeStatus.underdog => (
        underdogTag(underdogAlive),
        AppColors.white.withValues(alpha: .14),
        AppColors.white,
      ),
      PrizeStatus.waiting => (
        'depois',
        AppColors.white.withValues(alpha: .08),
        AppColors.white.withValues(alpha: .7),
      ),
    };
    return Container(
      margin: EdgeInsets.only(bottom: 8 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: st == PrizeStatus.open
            ? AppColors.white.withValues(alpha: .18)
            : AppColors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppText.body(16 * scale, color: AppColors.white),
                    children: [
                      TextSpan(
                        text: p.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' · ${modalityName(p)}'),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 10 * scale),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 4 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      13 * scale,
                      weight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (st == PrizeStatus.underdog)
            if (underdogNames(underdogAlive, players) case final names?)
              Padding(
                padding: EdgeInsets.only(top: 6 * scale),
                child: Text(
                  'Na disputa: $names',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    13 * scale,
                    color: AppColors.white.withValues(alpha: .85),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
