import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/penalty_evaluator.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';
import 'package:tokingo/features/game/presentation/player/choose_prize_overlay.dart';
import 'package:tokingo/features/game/presentation/player/player_game_controller.dart';
import 'package:tokingo/features/game/presentation/player/player_overlays.dart';

/// 09 – player's game screen (also the host's own card, 11b).
class PlayerGamePage extends StatefulWidget {
  const PlayerGamePage({required this.code, super.key});

  final RoomCode code;

  @override
  State<PlayerGamePage> createState() => _PlayerGamePageState();
}

class _PlayerGamePageState extends State<PlayerGamePage> {
  late final PlayerGameController _c;
  bool _help = false;
  bool _navigated = false;
  ItemId? _lastBall;

  @override
  void initState() {
    super.initState();
    _c = PlayerGameController(
      code: widget.code,
      repository: sl<GameRepository>(),
      presence: sl.isRegistered<PresenceRepository>()
          ? sl<PresenceRepository>()
          : null,
      auth: sl<AuthRepository>(),
      marks: sl<MarksStore>(),
      callBingo: sl<CallBingo>(),
      penalty: sl.isRegistered<PenaltyEvaluator>()
          ? sl<PenaltyEvaluator>()
          : const PenaltyEvaluator(),
    )..addListener(_onChange);
    unawaited(_c.start());
  }

  void _onChange() {
    final g = _c.game;
    if (g == null || !mounted) return;
    if (_c.isFinished && !_navigated) {
      _navigated = true;
      context.go(AppRoutes.result(widget.code));
      return;
    }
    // No card (opened /play directly): the room gate joins or shows an error.
    if (_c.cardChecked && _c.card == null && !_navigated) {
      _navigated = true;
      context.go(AppRoutes.room(widget.code));
      return;
    }
    final ball = g.currentBall;
    if (ball != null && ball != _lastBall) {
      if (_lastBall != null || g.draws.length == 1) {
        unawaited(announce(context, 'Nova bola: ${g.template.ballText(ball)}'));
      }
      _lastBall = ball;
    }
  }

  @override
  void dispose() {
    _c
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmBingoDialog(),
    );
    if (ok ?? false) await _c.callBingo();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final g = _c.game;
      if (_c.loading) return const GameLoadingView();
      if (g == null) {
        return const GameLoadingView(message: 'Sala não encontrada.');
      }
      final card = _c.card;
      return AppPage(
        blobs: const [
          Positioned(
            right: -180,
            top: -220,
            child: BlobShape(size: 560, color: AppColors.primary),
          ),
          Positioned(
            left: -200,
            bottom: -320,
            child: BlobShape(size: 520, color: AppColors.blob),
          ),
        ],
        child: Stack(
          children: [
            Column(
              children: [
                _PlayerHeader(
                  game: g,
                  user: _c.user,
                  isHost: _c.isHost,
                  onHelp: () => setState(() => _help = true),
                ),
                Expanded(
                  child: card == null
                      ? const Center(
                          child: TokenLoader(label: 'Buscando sua cartela…'),
                        )
                      : _PlayerBody(
                          game: g,
                          card: card,
                          controller: _c,
                          onBingo: _confirmAndSend,
                        ),
                ),
              ],
            ),
            if (!_c.hostOnline) const HostOfflineBanner(),
            if (_c.delivered case final d?)
              PrizeDeliveredOverlay(
                delivered: d,
                game: g,
                players: _c.players,
                claims: _c.claims,
                onClose: _c.dismissDelivered,
              ),
            if (_c.choiceClaim case final pick?)
              ChoosePrizeOverlay(
                claim: pick,
                game: g,
                players: _c.players,
                claims: _c.claims,
                busy: _c.choosing,
                onChoose: _c.choose,
              )
            else if (_c.overlay case final kind?)
              ClaimResultOverlay(
                kind: kind,
                claim: _c.followedClaim,
                game: g,
                onClose: _c.dismissOverlay,
              ),
            if (_help)
              HelpSidePanel(
                game: g,
                onClose: () => setState(() => _help = false),
              ),
          ],
        ),
      );
    },
  );
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.game,
    required this.user,
    required this.isHost,
    required this.onHelp,
  });

  final Game game;
  final AppUser? user;
  final bool isHost;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final info = Text.rich(
      TextSpan(
        style: AppText.body(narrow ? 13 : 16, weight: FontWeight.w300),
        children: [
          TextSpan(text: '${game.eventName} · sala '),
          TextSpan(
            text: game.roomCode.value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text:
                ' · ${game.playerCount}/${game.maxPlayers} jogadores · sala fechada',
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 40, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Wordmark(size: narrow ? 22 : 26),
              const SizedBox(width: 24),
              if (!narrow) Expanded(child: info) else const Spacer(),
              if (isHost && !narrow) ...[
                const _BackToPanelLink(),
                const SizedBox(width: 12),
              ],
              _HelpButton(onPressed: onHelp),
              const SizedBox(width: 12),
              if (user case final u?) _UserChip(user: u, compact: narrow),
            ],
          ),
          if (narrow) ...[
            const SizedBox(height: 8),
            info,
            if (isHost) ...[
              const SizedBox(height: 8),
              const _BackToPanelLink(),
            ],
          ],
        ],
      ),
    );
  }
}

class _BackToPanelLink extends StatelessWidget {
  const _BackToPanelLink();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_PlayerGamePageState>();
    return Semantics(
      link: true,
      child: Material(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: state == null
              ? null
              : () => context.go(AppRoutes.host(state.widget.code)),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            child: Text(
              'Você é o host · voltar ao painel',
              style: AppText.body(
                14,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Como jogar',
    child: ExcludeSemantics(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                '?',
                style: AppText.display(18, color: AppColors.navy),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user, required this.compact});

  final AppUser user;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(6, 6, compact ? 6 : 14, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarToken(initials: user.initials, size: 36),
          if (!compact) ...[
            const SizedBox(width: 12),
            Text(user.displayName.split(' ').first, style: AppText.body(14)),
          ],
        ],
      ),
    ),
  );
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.game,
    required this.card,
    required this.controller,
    required this.onBingo,
  });

  final Game game;
  final BingoCard card;
  final PlayerGameController controller;
  final VoidCallback onBingo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 1100;
      final ball = _CurrentBall(game: game, size: wide ? 260 : 150);
      final center = _CardAndBingo(
        game: game,
        card: card,
        controller: controller,
        onBingo: onBingo,
        // Wide: BINGO lives in the right column, under the next prizes.
        showBingo: !wide,
      );
      final prizes = PrizeSidebar(game: game, players: controller.players);
      if (wide) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 16, 40, 32),
          child: Row(
            children: [
              SizedBox(width: 380, child: ball),
              const SizedBox(width: 32),
              Expanded(
                child: Center(child: SingleChildScrollView(child: center)),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 340,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        prizes,
                        const SizedBox(height: 16),
                        _BingoWithError(
                          controller: controller,
                          onBingo: onBingo,
                          height: 60,
                          fontSize: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            ball,
            const SizedBox(height: 16),
            center,
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: prizes,
            ),
          ],
        ),
      );
    },
  );
}

class _CurrentBall extends StatelessWidget {
  const _CurrentBall({required this.game, required this.size});

  final Game game;
  final double size;

  @override
  Widget build(BuildContext context) {
    final wide = size > 200;
    final token = BallToken(
      template: game.template,
      ball: game.currentBall,
      size: size,
    );
    if (wide) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SplitTitle('bola', 'atual', size: 26),
          const SizedBox(height: 24),
          token,
        ],
      );
    }
    // Phone: title shrinks to fit beside the token instead of overflowing.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SplitTitle('bola', 'atual', size: 26),
          ),
        ),
        const SizedBox(width: 20),
        token,
      ],
    );
  }
}

class _CardAndBingo extends StatelessWidget {
  const _CardAndBingo({
    required this.game,
    required this.card,
    required this.controller,
    required this.onBingo,
    this.showBingo = true,
  });

  final Game game;
  final BingoCard card;
  final PlayerGameController controller;
  final VoidCallback onBingo;
  final bool showBingo;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerCard(
          game: game,
          card: card,
          marked: controller.marked,
          onToggle: controller.toggle,
        ),
        if (showBingo) ...[
          const SizedBox(height: 20),
          _BingoWithError(controller: controller, onBingo: onBingo),
        ],
      ],
    ),
  );
}

/// The card with MANUAL stamping only (R13): no highlight of drawn numbers.
class PlayerCard extends StatelessWidget {
  const PlayerCard({
    required this.game,
    required this.card,
    required this.marked,
    required this.onToggle,
    super.key,
  });

  final Game game;
  final BingoCard card;
  final Set<int> marked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = game.template;
    final free = t.freeCellIndex;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A424041),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(narrow ? 12 : 22),
        child: BingoGrid(
          headers: [for (var c = 0; c < t.cols; c++) t.header(c)],
          headerColors: t.columnColors,
          cols: t.cols,
          gap: narrow ? 6 : 10,
          headerHeight: narrow ? 36 : 52,
          cellFontSize: narrow ? 20 : 30,
          cells: [
            for (final (i, id) in card.cells.indexed)
              if (i == free || id == null)
                GridCell(
                  label: t.free.label,
                  background: AppColors.light,
                  semanticsLabel: 'Livre',
                )
              else
                GridCell(
                  label: t.item(id).label,
                  stamped: marked.contains(i),
                  stampRotation: stampRotation(i, t.cols),
                  semanticsLabel:
                      '${t.ballText(id)}${marked.contains(i) ? ', marcado' : ''}',
                  onTap: () => onToggle(i),
                ),
          ],
        ),
      ),
    );
  }
}

/// BINGO button plus the send error under it.
class _BingoWithError extends StatelessWidget {
  const _BingoWithError({
    required this.controller,
    required this.onBingo,
    this.height = 76,
    this.fontSize = 34,
  });

  final PlayerGameController controller;
  final VoidCallback onBingo;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      BingoButton(
        blockedReason: controller.bingoBlockedReason,
        sending: controller.sending,
        onPressed: onBingo,
        height: height,
        fontSize: fontSize,
      ),
      if (controller.sendError case final err?)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            err,
            style: AppText.body(
              14,
              weight: FontWeight.w700,
              color: AppColors.purple,
            ),
          ),
        ),
    ],
  );
}

/// BINGO – always the same visual (R13). Only disabled with a written reason.
class BingoButton extends StatelessWidget {
  const BingoButton({
    required this.blockedReason,
    required this.sending,
    required this.onPressed,
    super.key,
    this.height = 76,
    this.fontSize = 34,
  });

  final String? blockedReason;
  final bool sending;
  final VoidCallback onPressed;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final blocked = blockedReason != null;
    return Semantics(
      button: true,
      enabled: !blocked && !sending,
      label: blocked ? blockedReason : 'BINGO!',
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Material(
            color: blocked ? AppColors.light : AppColors.navy,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: blocked || sending ? null : onPressed,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    blockedReason ?? 'BINGO!',
                    textAlign: TextAlign.center,
                    style:
                        AppText.display(
                          blocked ? fontSize * 22 / 34 : fontSize,
                          color: blocked
                              ? const Color(0xFF6B6869)
                              : AppColors.white,
                        ).copyWith(
                          letterSpacing:
                              (blocked ? fontSize * 22 / 34 : fontSize) * .06,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "VALENDO AGORA" (every open prize) + "PRÓXIMOS PRÊMIOS" + "JÁ SAÍRAM".
class PrizeSidebar extends StatelessWidget {
  const PrizeSidebar({required this.game, this.players = const [], super.key});

  final Game game;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final open = game.openPrizes;
    final all = game.displayPrizes;
    final next = [
      for (final p in all)
        if (prizeStatus(game, p)
            case PrizeStatus.waiting || PrizeStatus.underdog)
          p,
    ];
    final won = [
      for (final p in all)
        if (game.isWon(p.id)) p,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VALENDO AGORA', style: AppText.kicker()),
              if (open.isEmpty) ...[
                const SizedBox(height: 10),
                Text('—', style: AppText.display(24, color: AppColors.navy)),
              ],
              for (final (i, p) in open.indexed) ...[
                SizedBox(height: i == 0 ? 10 : 16),
                Text(
                  p.label,
                  style: AppText.display(24, color: AppColors.navy),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: AppText.body(15),
                    children: [
                      const TextSpan(text: 'Modalidade: '),
                      TextSpan(
                        text: modalityName(p),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' (${modalityHint(p.pattern)})'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (next.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRÓXIMOS PRÊMIOS', style: AppText.kicker()),
                for (final p in next) ...[
                  const SizedBox(height: 8),
                  Text(
                    p.pattern == PatternKind.underdog
                        ? '${p.label} · por eliminação, durante o jogo'
                        : '${p.label} · ${modalityName(p)}',
                    style: AppText.body(14),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (won.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JÁ SAÍRAM', style: AppText.kicker()),
                for (final p in won) ...[
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: AppText.body(14),
                      children: [
                        TextSpan(text: '${p.label} · '),
                        TextSpan(
                          text: '🏆 ${winnerNames(game, p, players)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
