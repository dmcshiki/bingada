import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';
import 'package:tokingo/features/game/presentation/common/tie_player_card.dart';
import 'package:tokingo/features/stream/presentation/stream_controller.dart';

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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final bg = widget.chroma ? _chromaGreen : AppColors.navy;
      final g = _c.game;
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
                    ? StreamFinished(game: g, players: _c.players)
                    : _StreamBoard(
                        game: g,
                        players: _c.players,
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
  });

  final Game game;
  final List<Player> players;
  final bool compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = !compact && box.maxWidth >= 1100;
      // Scale everything from the 1600px-wide canvas.
      final scale = wide ? (box.maxWidth / 1600).clamp(.7, 1.4) : 1.0;
      final board = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'tokingo',
            style: AppText.display(30 * scale, color: AppColors.white),
          ),
          SizedBox(height: 16 * scale),
          PoolBoard(
            template: game.template,
            drawn: game.draws.toSet(),
            dark: true,
            cellHeight: (wide ? 40 : 30) * scale,
          ),
        ],
      );
      final ball = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SplitTitle('bola', 'atual', size: 22 * scale, color: AppColors.white),
          SizedBox(height: 28 * scale),
          BallToken(
            template: game.template,
            ball: game.currentBall,
            size: (wide ? 380 : 220) * scale,
          ),
        ],
      );
      final last = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LastBalls(game: game, scale: scale),
          SizedBox(height: 28 * scale),
          _StreamPrizes(game: game, players: players, scale: scale),
        ],
      );
      final footer = _StreamFooter(game: game, scale: scale);
      if (compact) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ball,
              const SizedBox(height: 24),
              last,
              const SizedBox(height: 24),
              footer,
            ],
          ),
        );
      }
      if (!wide) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ball,
              const SizedBox(height: 24),
              last,
              const SizedBox(height: 24),
              board,
              const SizedBox(height: 24),
              footer,
            ],
          ),
        );
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(
          48 * scale,
          40 * scale,
          48 * scale,
          28 * scale,
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 520 * scale,
                    child: SingleChildScrollView(child: board),
                  ),
                  SizedBox(width: 32 * scale),
                  Expanded(child: ball),
                  SizedBox(width: 32 * scale),
                  SizedBox(
                    width: 400 * scale,
                    child: SingleChildScrollView(child: last),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20 * scale),
            footer,
          ],
        ),
      );
    },
  );
}

class _LastBalls extends StatelessWidget {
  const _LastBalls({required this.game, required this.scale});

  final Game game;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final recent = game.draws.reversed.skip(1).take(5).toList();
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
        Semantics(
          label: recent.isEmpty
              ? 'Nenhuma bola anterior'
              : 'Últimas bolas: ${recent.map(game.template.ballText).join(', ')}',
          child: ExcludeSemantics(
            child: Wrap(
              spacing: 10 * scale,
              runSpacing: 10 * scale,
              children: [
                for (final id in recent)
                  Container(
                    width: 68 * scale,
                    height: 68 * scale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18 * scale),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(
                        child: Text(
                          game.template.ballShort(id),
                          style: AppText.display(
                            20 * scale,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
      kicker: 'BINGO!',
      name: playerName(players, claim.uid),
      uid: claim.uid,
      badge:
          'VÁLIDO · ${describeMatches(claim.matched, game.template, prize: prize)}',
      badgeBg: AppColors.greenDark,
      badgeFg: AppColors.white,
      text: 'Levou a ${prize?.label ?? ''}. ${_next(game)}',
    ),
    MissedOverlay(:final claim) => _OneOverlay(
      kicker: 'BINGO?',
      name: playerName(players, claim.uid),
      uid: claim.uid,
      badge: 'COMEU BOLA',
      badgeBg: AppColors.purple,
      badgeFg: AppColors.white,
      text:
          'Marcou bola que ainda não saiu. O jogo continua valendo a ${game.currentPrize?.label ?? ''}.',
    ),
    UnderdogOverlay(:final prize, :final winners) => _OneOverlay(
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
      game: game,
      players: players,
      tied: tied.map((c) => c.uid).toList(),
      prize: prize,
      winners: winners,
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

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
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
    return ScrimOverlay(
      color: const Color(0xD1142840),
      child: Semantics(
        liveRegion: true,
        child: DialogCard(
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
        ),
      ),
    );
  }
}

class _TieOverlay extends StatelessWidget {
  const _TieOverlay({
    required this.game,
    required this.players,
    required this.tied,
    required this.prize,
    required this.winners,
  });

  final Game game;
  final List<Player> players;
  final List<UserId> tied;
  final Prize? prize;
  final Set<UserId>? winners;

  @override
  Widget build(BuildContext context) {
    final w = winners;
    final done = w != null;
    final next = game.currentPrize;
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
                  'EMPATE · ${prize?.label.toUpperCase() ?? ''} · '
                  '${prize == null ? '' : modalityName(prize!).toUpperCase()} · NA MESMA BOLA',
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
            EllipsisText(
              done ? 'Desempate decidido!' : 'Sorteando o desempate…',
              textAlign: TextAlign.center,
              style: AppText.display(56, color: AppColors.white),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 56,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                for (final uid in tied)
                  TiePlayerCard(
                    name: playerName(players, uid),
                    uid: uid,
                    width: 400,
                    winnerTag: 'LEVOU A ${prize?.label.toUpperCase() ?? ''}',
                    state: !done
                        ? TieCardState.pending
                        : w.contains(uid)
                        ? TieCardState.winner
                        : TieCardState.loser,
                  ),
              ],
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

/// Summary shown on the stream once the game is over (read-only).
class StreamFinished extends StatelessWidget {
  const StreamFinished({required this.game, required this.players, super.key});

  final Game game;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final all = [...game.prizes, ...game.endOfGamePrizes];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            SplitTitle(
              'fim de',
              game.status == GameStatus.abandoned
                  ? 'jogo (encerrado pelo host)'
                  : 'jogo!',
              size: 56,
              color: AppColors.white,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                for (final p in all)
                  for (final w in game.winners.where((w) => w.prizeId == p.id))
                    SizedBox(
                      width: 360,
                      child: SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.label.toUpperCase(),
                              style: AppText.kicker(color: AppColors.navy),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                NameToken(
                                  name: playerName(players, w.uid),
                                  uid: w.uid,
                                  size: 56,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    playerName(players, w.uid),
                                    style: AppText.display(22),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
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
  });

  final Game game;
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
        'por eliminação',
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
      child: Row(
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
    );
  }
}
