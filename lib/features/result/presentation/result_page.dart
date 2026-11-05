import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_watch_controller.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';

/// 14 – end of game: winners, underdog, audit and "new game".
class ResultPage extends StatefulWidget {
  const ResultPage({required this.code, super.key});

  final RoomCode code;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final GameWatchController _c;
  late final ConfettiController _confetti;
  List<BingoCard> _cards = const [];
  GameId? _cardsFor;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _c = GameWatchController(
      code: widget.code,
      repository: sl<GameRepository>(),
    )..addListener(_onChange);
    unawaited(_c.start());
  }

  void _onChange() {
    final g = _c.game;
    if (g == null || !_c.isFinished || _cardsFor == g.id) return;
    _cardsFor = g.id;
    unawaited(_loadCards(g.id));
    if (mounted && !MediaQuery.disableAnimationsOf(context)) _confetti.play();
  }

  Future<void> _loadCards(GameId id) async {
    try {
      final cards = await sl<GameRepository>().getCards(id);
      if (mounted) setState(() => _cards = cards);
    } on Object {
      // Underdog detail is optional.
    }
  }

  @override
  void dispose() {
    _c
      ..removeListener(_onChange)
      ..dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      if (_c.loading) return const GameLoadingView();
      final g = _c.game;
      if (g == null) {
        return const GameLoadingView(message: 'Sala não encontrada.');
      }
      if (!_c.isFinished) {
        return const GameLoadingView(
          message: 'A partida ainda está em andamento.',
        );
      }
      final auth = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>()
          : null;
      final isHost = auth?.currentUser?.uid == g.hostUid;
      return Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          children: [
            const Positioned(
              right: -160,
              top: -200,
              child: BlobShape(size: 560, color: AppColors.deepBlue),
            ),
            // Static confetti tokens from the canvas (14).
            for (var k = 0; k < 14; k++)
              Positioned(
                left: 640.0 + (k * 53) % 700,
                top: 40.0 + (k * 97) % 200,
                child: ExcludeSemantics(
                  child: Transform.rotate(
                    angle: ((k * 37) % 90) * math.pi / 180,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.columns[k % 5],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: SafeArea(
                child: ResultView(
                  game: g,
                  players: _c.players,
                  claims: _c.claims,
                  cards: _cards,
                  isHost: isHost,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ExcludeSemantics(
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 24,
                  colors: AppColors.columns,
                  minimumSize: const Size(12, 12),
                  maximumSize: const Size(18, 18),
                  createParticlePath: _tokenPath,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 13px bold kicker with .05em tracking (GameOver canvas).
TextStyle _kicker(Color color) =>
    AppText.body(13, weight: FontWeight.w700, color: color, letterSpacing: .65);

/// Translucent rounded box with a 2px dashed outline (underdog card).
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.fill,
    required this.color,
    required this.radius,
  });

  final Color fill;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.fill != fill || old.color != color || old.radius != radius;
}

/// Confetti shaped like small rounded tokens.
Path _tokenPath(Size size) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * .28),
    ),
  );

class ResultView extends StatelessWidget {
  const ResultView({
    required this.game,
    required this.players,
    required this.claims,
    required this.cards,
    required this.isHost,
    super.key,
  });

  final Game game;
  final List<Player> players;
  final List<Claim> claims;
  final List<BingoCard> cards;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final sequential = [
      for (final (i, p) in game.prizes.indexed)
        for (final w in game.winners.where((w) => w.prizeId == p.id)) (i, p, w),
    ];
    final underdogs = [
      for (final p in game.endOfGamePrizes)
        for (final w in game.winners.where((w) => w.prizeId == p.id)) (p, w),
    ];
    final lastSequentialId = game.prizes.isEmpty ? null : game.prizes.last.id;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 16 : 72,
        vertical: narrow ? 24 : 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              const Wordmark(size: 28, color: AppColors.white),
              Text(
                '${game.eventName} · ${game.status == GameStatus.abandoned ? 'encerrado pelo host' : 'encerrado'} na bola ${game.draws.length}',
                style: AppText.body(15, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SplitTitle(
            'fim de',
            'jogo!',
            size: narrow ? 40 : 56,
            color: AppColors.white,
          ),
          const SizedBox(height: 28),
          if (sequential.isEmpty)
            Text(
              'Nenhum prêmio sequencial foi entregue.',
              style: AppText.body(16, color: AppColors.white),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final perRow = box.maxWidth >= 1000
                    ? 3
                    : (box.maxWidth >= 640 ? 2 : 1);
                final w = (box.maxWidth - 20 * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    for (final (i, p, win) in sequential)
                      SizedBox(
                        width: w,
                        height: 200,
                        child: _WinnerCard(
                          title: '${i + 1} · ${p.label.toUpperCase()}',
                          name: playerName(players, win.uid),
                          uid: win.uid,
                          how: _how(
                            p,
                            win,
                            ends:
                                game.status == GameStatus.finished &&
                                p.id == lastSequentialId,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 20),
          if (game.endOfGamePrizes.isEmpty)
            Align(
              alignment: narrow ? Alignment.center : Alignment.centerRight,
              child: SizedBox(
                width: narrow ? double.infinity : 460,
                child: _AuditBox(game: game, isHost: isHost),
              ),
            )
          else
            IntrinsicHeight(
              child: Flex(
                direction: narrow ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (narrow)
                    _UnderdogBox(
                      game: game,
                      players: players,
                      cards: cards,
                      underdogs: underdogs,
                    )
                  else
                    Expanded(
                      child: _UnderdogBox(
                        game: game,
                        players: players,
                        cards: cards,
                        underdogs: underdogs,
                      ),
                    ),
                  const SizedBox(width: 20, height: 20),
                  if (narrow)
                    _AuditBox(game: game, isHost: isHost)
                  else
                    SizedBox(
                      width: 460,
                      child: _AuditBox(game: game, isHost: isHost),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _how(Prize p, Winner w, {required bool ends}) {
    final parts = [
      modalityName(p),
      ballOrdinal(w.drawIndex),
      if (w.tieBreak) 'venceu o desempate',
      if (ends) 'encerrou o jogo',
    ];
    return parts.join(' · ');
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.title,
    required this.name,
    required this.uid,
    required this.how,
  });

  final String title;
  final String name;
  final UserId uid;
  final String how;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _kicker(AppColors.navy),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            NameToken(name: name, uid: uid, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(24, color: AppColors.graphite),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          how,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(14),
        ),
      ],
    ),
  );
}

class _UnderdogBox extends StatelessWidget {
  const _UnderdogBox({
    required this.game,
    required this.players,
    required this.cards,
    required this.underdogs,
  });

  final Game game;
  final List<Player> players;
  final List<BingoCard> cards;
  final List<(Prize, Winner)> underdogs;

  /// Azarão by elimination: the winner survived up to [Winner.drawIndex].
  String _detail(Winner w) {
    final n = w.drawIndex;
    final balls = n == 1 ? '1 bola' : '$n bolas';
    if (w.tieBreak) {
      return 'Saiu junto com outros na mesma rodada, depois de $balls, '
          'e venceu o sorteio de desempate.';
    }
    return 'Último a sobrar: resistiu $balls sem nenhum número na cartela. '
        'Respeito.';
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _DashedRRectPainter(
      fill: Color(0x1AFFFFFF),
      color: AppColors.pink,
      radius: 28,
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: underdogs.isEmpty
          ? Text(
              'Ninguém elegível para o azarão.',
              style: AppText.body(15, color: AppColors.white),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (p, w) in underdogs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(
                              child: AvatarToken(
                                initials: initialsOf(
                                  playerName(players, w.uid),
                                ),
                                size: 72,
                                color: AppColors.pink,
                                photoUrl: playerPhotos[w.uid],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.label.toUpperCase(),
                                style: _kicker(AppColors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                playerName(players, w.uid),
                                style: AppText.display(
                                  26,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _detail(w),
                                style: AppText.body(14, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    ),
  );
}

class _AuditBox extends StatelessWidget {
  const _AuditBox({required this.game, required this.isHost});

  final Game game;
  final bool isHost;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partida verificável',
          style: AppText.body(16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          game.drawSeed == null ? 'Seed do sorteio ainda não revelada ⚠️.' : 'Seed do sorteio revelada. Qualquer pessoa pode conferir sorteio, cartelas e vencedores.',
          style: AppText.body(14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AppButton(
              label: 'Auditar partida',
              height: 48,
              fontSize: 14,
              onPressed: () => context.go(AppRoutes.verify(game.id)),
            ),
            if (isHost)
              AppButton(
                label: 'Novo jogo (host)',
                kind: AppButtonKind.secondary,
                height: 48,
                fontSize: 14,
                onPressed: () => context.go(AppRoutes.createFrom(game.id)),
              ),
          ],
        ),
      ],
    ),
  );
}
