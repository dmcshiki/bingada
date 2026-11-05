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
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/bingo_verifier.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';
import 'package:tokingo/features/game/presentation/host/host_panel_controller.dart';
import 'package:tokingo/features/game/presentation/player/player_game_page.dart';
import 'package:tokingo/features/game/presentation/tiebreak/tiebreak_dialog.dart';
import 'package:tokingo/features/game/presentation/verify_claim/verify_claim_dialog.dart';
import 'package:tokingo/features/room/presentation/waiting/open_tab.dart';

/// 11 – host panel (with 11c end confirm, 12 verify, 12b tiebreak).
class HostPanelPage extends StatefulWidget {
  const HostPanelPage({required this.code, super.key});

  final RoomCode code;

  @override
  State<HostPanelPage> createState() => _HostPanelPageState();
}

class _HostPanelPageState extends State<HostPanelPage> {
  late final HostPanelController _c;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = HostPanelController(
      code: widget.code,
      repository: sl<GameRepository>(),
      drawNext: sl<DrawNext>(),
      verifyClaim: sl<VerifyClaim>(),
      resolveClaim: sl<ResolveClaim>(),
      resolveTie: sl<ResolveTie>(),
      confirmPrize: sl<ConfirmPrize>(),
      endGame: sl<EndGame>(),
      verifier: sl.isRegistered<BingoVerifier>()
          ? sl<BingoVerifier>()
          : const BingoVerifier(),
      presence: sl.isRegistered<PresenceRepository>()
          ? sl<PresenceRepository>()
          : null,
      awardUnderdog: sl.isRegistered<AwardUnderdog>()
          ? sl<AwardUnderdog>()
          : null,
    )..addListener(_onChange);
    unawaited(_c.start());
  }

  void _onChange() {
    if (!mounted || _navigated || !_c.isFinished) return;
    _navigated = true;
    context.go(AppRoutes.result(widget.code));
  }

  @override
  void dispose() {
    _c
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  Future<void> _openVerify(Claim claim) async {
    final action = await showDialog<VerifyAction>(
      context: context,
      barrierColor: const Color(0xEB424041),
      builder: (_) => VerifyClaimDialog(controller: _c, claimId: claim.id),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case VerifyReject(:final claim):
        await _c.reject(claim);
      case VerifyConfirm(:final claim):
        await _c.confirmSingle(claim);
      case VerifyConfirmAll(:final tied):
        await _c.confirmAll(tied);
      case VerifyGoTiebreak(:final tied):
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => TiebreakDialog(controller: _c, tied: tied),
        );
    }
  }

  bool get _hostHasCard {
    final uid = sl<AuthRepository>().currentUser?.uid;
    return uid != null && _c.players.any((p) => p.uid == uid);
  }

  Future<void> _confirmEnd() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xCC424041),
      builder: (_) => EndGameDialog(game: _c.game!),
    );
    if (ok ?? false) await _c.endEarly();
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
      final board = _BoardPanel(
        game: g,
        myCard: _hostHasCard
            ? PlayerGamePage(code: widget.code, embedded: true)
            : null,
      );
      final center = _DrawPanel(controller: _c, game: g, onEnd: _confirmEnd);
      final side = _SidePanel(controller: _c, game: g, onOpen: _openVerify);
      return Scaffold(
        backgroundColor: AppColors.light,
        body: SafeArea(
          child: Column(
            children: [
              _HostHeader(game: g),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    if (box.maxWidth >= 700) {
                      // Wide layout designed for >= 1260x760; on smaller
                      // monitors it is scaled down to fit both axes.
                      final w = box.maxWidth < 1260 ? 1260.0 : box.maxWidth;
                      final h = box.maxHeight < 760 ? 760.0 : box.maxHeight;
                      return FittedBox(
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 420,
                                  child: SingleChildScrollView(child: board),
                                ),
                                const SizedBox(width: 20),
                                Expanded(child: center),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 420,
                                  child: SingleChildScrollView(child: side),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(height: 520, child: center),
                          const SizedBox(height: 16),
                          side,
                          const SizedBox(height: 16),
                          board,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HostHeader extends StatelessWidget {
  const _HostHeader({required this.game});

  final Game game;

  String get _access => switch (game.access) {
    DomainAccess(:final domains) =>
      'Acesso: ${domains.map((d) => '@$d').join(', ')}',
    SameAsHostAccess(:final hostDomain) => 'Acesso: @$hostDomain',
    AllowlistAccess(:final emails) => 'Acesso: ${emails.length} convidados',
    PublicAccess() => 'Acesso: público',
  };

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    return Container(
      width: double.infinity,
      color: AppColors.graphite,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 28, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Wordmark(size: 24, color: AppColors.white),
              const SizedBox(width: 18),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: AppText.body(
                      16,
                      weight: FontWeight.w300,
                      color: AppColors.white,
                    ),
                    children: [
                      const TextSpan(text: 'painel do '),
                      const TextSpan(
                        text: 'host',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            ' · Sala ${game.roomCode.value} · ${game.eventName}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Pill(
                label: _access,
                color: AppColors.navy,
                textColor: AppColors.white,
              ),
              Semantics(
                link: true,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      final path = AppRoutes.stream(game.roomCode);
                      if (!openInNewTab(path)) context.go(path);
                    },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          'Abrir tela de transmissão ↗',
                          style: AppText.body(
                            14,
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({required this.game, this.myCard});

  final Game game;

  /// The host's own card (embedded player view), when they play.
  final Widget? myCard;

  @override
  Widget build(BuildContext context) {
    final commit = game.drawCommit;
    final short = commit.length > 8
        ? '${commit.substring(0, 4)}…${commit.substring(commit.length - 4)}'
        : commit;
    return SectionCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SplitTitle('tabela de', 'bolas', size: 20),
          const SizedBox(height: 10),
          PoolBoard(
            template: game.template,
            drawn: game.draws.toSet(),
            current: game.currentBall,
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: AppText.body(12),
              children: [
                const TextSpan(text: 'Commit do sorteio: '),
                TextSpan(text: short, style: AppText.mono(12)),
                const TextSpan(text: ' · revelado ao fim'),
              ],
            ),
          ),
          if (myCard case final card?) ...[
            const SizedBox(height: 24),
            const SplitTitle('minha', 'cartela', size: 20),
            const SizedBox(height: 12),
            card,
          ],
        ],
      ),
    );
  }
}

class _DrawPanel extends StatelessWidget {
  const _DrawPanel({
    required this.controller,
    required this.game,
    required this.onEnd,
  });

  final HostPanelController controller;
  final Game game;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final blocked = controller.drawBlockedReason;
    final total = game.template.pool.length;
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: AppColors.navy,
              child: Stack(
                children: [
                  const Positioned(
                    left: -90,
                    bottom: -120,
                    child: BlobShape(size: 320, color: AppColors.deepBlue),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (box.maxHeight - 32).clamp(
                              0,
                              double.infinity,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Host only: the ball count is allowed here (R23).
                              Text(
                                'bola ${game.draws.length} de $total · valendo: '
                                '${openPrizesText(game)}',
                                textAlign: TextAlign.center,
                                style: AppText.body(14, color: AppColors.white),
                              ),
                              const SizedBox(height: 18),
                              if (game.raffle case final r?) ...[
                                _RaffleBox(
                                  raffle: r,
                                  game: game,
                                  players: controller.players,
                                  busy: controller.busy,
                                  onDraw: () =>
                                      unawaited(controller.runRaffle()),
                                ),
                                const SizedBox(height: 18),
                              ],
                              BallToken(
                                template: game.template,
                                ball: game.currentBall,
                                size: 230,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 64,
                                child: controller.drawing
                                    ? Semantics(
                                        liveRegion: true,
                                        label: 'Sorteando',
                                        child: Container(
                                          width: 190,
                                          height: 64,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const LoadingDots(
                                            color: AppColors.navy,
                                            dotSize: 12,
                                          ),
                                        ),
                                      )
                                    : AppButton(
                                        label: 'SORTEAR',
                                        kind: AppButtonKind.light,
                                        height: 64,
                                        displayFont: true,
                                        fontSize: 24,
                                        onPressed:
                                            blocked != null || controller.busy
                                            ? null
                                            : () =>
                                                  unawaited(controller.draw()),
                                      ),
                              ),
                              if (blocked != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  blocked,
                                  textAlign: TextAlign.center,
                                  style: AppText.body(
                                    13,
                                    weight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                              if (controller.actionError case final err?) ...[
                                const SizedBox(height: 10),
                                Text(
                                  err,
                                  textAlign: TextAlign.center,
                                  style: AppText.body(
                                    13,
                                    weight: FontWeight.w700,
                                    color: AppColors.pink,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  AppButton(
                    label: 'Encerrar partida',
                    kind: AppButtonKind.outline,
                    height: 44,
                    fontSize: 13,
                    // Every BINGO must be checked before ending.
                    onPressed:
                        controller.busy || controller.endBlockedReason != null
                        ? null
                        : onEnd,
                  ),
                  if (controller.endBlockedReason case final why?)
                    Text(why, style: AppText.body(12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// On-screen draw of a prize (azarão tie or a prize given up). Pending: the
/// host presses SORTEAR; decided: shows who won until the next ball.
class _RaffleBox extends StatelessWidget {
  const _RaffleBox({
    required this.raffle,
    required this.game,
    required this.players,
    required this.busy,
    required this.onDraw,
  });

  final Raffle raffle;
  final Game game;
  final List<Player> players;
  final bool busy;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    final prize = game.prizeById(raffle.prizeId);
    final label = prize?.label ?? 'Prêmio';
    final why = switch (raffle.kind) {
      RaffleKind.underdogTie => 'Empate no azarão: saíram todos na mesma bola',
      RaffleKind.released when raffle.releasedBy != null =>
        '${playerName(players, raffle.releasedBy!)} abriu mão deste prêmio',
      RaffleKind.released => 'Ninguém ficou com este prêmio',
    };
    final names = [for (final u in raffle.candidates) playerName(players, u)]
        .join(', ');
    final winner = raffle.winner;
    return Container(
      width: 520,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'SORTEIO · ${label.toUpperCase()}',
            textAlign: TextAlign.center,
            style: AppText.kicker(color: AppColors.white),
          ),
          const SizedBox(height: 6),
          Text(
            winner == null
                ? '$why. Entre: $names.'
                : '🏆 ${playerName(players, winner)} ganhou $label no sorteio.',
            textAlign: TextAlign.center,
            style: AppText.body(
              15,
              weight: winner == null ? FontWeight.w400 : FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          if (winner == null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'SORTEAR ${label.toUpperCase()}',
              kind: AppButtonKind.light,
              height: 52,
              displayFont: true,
              fontSize: 18,
              onPressed: busy ? null : onDraw,
            ),
          ],
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.controller,
    required this.game,
    required this.onOpen,
  });

  final HostPanelController controller;
  final Game game;
  final ValueChanged<Claim> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ClaimsQueue(controller: controller, game: game, onOpen: onOpen),
      const SizedBox(height: 20),
      _PrizeList(
        game: game,
        players: controller.players,
        underdogAlive: controller.underdogAlive,
      ),
      const SizedBox(height: 20),
      _PlayersList(game: game, players: controller.players),
    ],
  );
}

class _ClaimsQueue extends StatelessWidget {
  const _ClaimsQueue({
    required this.controller,
    required this.game,
    required this.onOpen,
  });

  final HostPanelController controller;
  final Game game;
  final ValueChanged<Claim> onOpen;

  @override
  Widget build(BuildContext context) {
    final pending = controller.pendingClaims;
    return SectionCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SplitTitle('pedidos de', 'bingo', size: 20),
          const SizedBox(height: 12),
          if (pending.isEmpty)
            Text('Nenhum pedido agora.', style: AppText.body(14))
          else
            for (final c in pending) ...[
              ClaimQueueTile(
                claim: c,
                result: controller.results[c.id],
                name: playerName(controller.players, c.uid),
                game: game,
                onTap: () => onOpen(c),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

/// One row in the claims queue with the auto-verification verdict.
class ClaimQueueTile extends StatelessWidget {
  const ClaimQueueTile({
    required this.claim,
    required this.result,
    required this.name,
    required this.game,
    required this.onTap,
    super.key,
  });

  final Claim claim;
  final ClaimResult? result;
  final String name;
  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final prize = prizeById(game, claim.prizeId);
    final (bg, tag, tagColor) = switch (r?.verdict) {
      null => (AppColors.surfaceSoft, 'conferindo…', AppColors.graphite),
      ClaimVerdict.valid => (
        const Color(0xFFEAF6EC),
        '✓ válido',
        const Color(0xFF2E7D3A),
      ),
      ClaimVerdict.missed => (
        const Color(0xFFF3EAFA),
        '✕ comeu bola',
        AppColors.purple,
      ),
      ClaimVerdict.wrongPattern => (
        const Color(0xFFF3EAFA),
        '! modalidade errada',
        AppColors.purple,
      ),
      ClaimVerdict.notEligible => (
        AppColors.surfaceSoft,
        '✕ não elegível',
        AppColors.graphite,
      ),
      ClaimVerdict.penalized => (
        AppColors.surfaceSoft,
        '✕ penalidade',
        AppColors.graphite,
      ),
      ClaimVerdict.tampered => (
        AppColors.surfaceSoft,
        '✕ cartela adulterada',
        AppColors.graphite,
      ),
    };
    final how = r != null && r.matched.isNotEmpty
        ? describeMatches(r.matched, game.template, prize: prize)
        : (prize == null ? '' : modalityName(prize));
    return Semantics(
      button: true,
      label:
          '$name, $how, ${ballOrdinal(claim.drawIndex)}, $tag. Abrir verificação',
      child: ExcludeSemantics(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  NameToken(name: name, uid: claim.uid, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppText.body(14),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: '\n$how · ${ballOrdinal(claim.drawIndex)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  EllipsisText(
                    tag,
                    style: AppText.body(
                      12,
                      weight: FontWeight.w700,
                      color: tagColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrizeList extends StatelessWidget {
  const _PrizeList({
    required this.game,
    required this.players,
    this.underdogAlive,
  });

  final Game game;
  final List<UserId>? underdogAlive;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final all = game.displayPrizes;
    return SectionCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SplitTitle('', 'prêmios', size: 20),
          const SizedBox(height: 8),
          for (final (i, p) in all.indexed)
            Builder(
              builder: (context) {
                final st = prizeStatus(game, p);
                final current = st == PrizeStatus.open;
                final who = winnerNames(game, p, players);
                final status = switch (st) {
                  PrizeStatus.won => who,
                  PrizeStatus.open => 'valendo',
                  PrizeStatus.underdog => underdogTag(underdogAlive),
                  PrizeStatus.waiting => 'depois',
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: current ? const Color(0xFFDCE6F4) : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text('${i + 1}', style: AppText.display(14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: AppText.body(14),
                            children: [
                              TextSpan(
                                text: p.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: ' · ${modalityName(p)}'),
                              if (st == PrizeStatus.underdog)
                                if (underdogNames(underdogAlive, players)
                                    case final names?)
                                  TextSpan(
                                    text: '\nNa disputa: $names',
                                    style: AppText.body(12),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          st == PrizeStatus.won ? '🏆 $status' : status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: AppText.body(
                            12,
                            weight: FontWeight.w700,
                            color: st == PrizeStatus.won
                                ? AppColors.greenDark
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Online players only. No proximity of any kind (R17).
class _PlayersList extends StatelessWidget {
  const _PlayersList({required this.game, required this.players});

  final Game game;
  final List<Player> players;

  @override
  Widget build(BuildContext context) => SectionCard(
    radius: 24,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SplitTitle(
          'jogadores',
          '${game.playerCount}/${game.maxPlayers}',
          size: 20,
        ),
        const SizedBox(height: 10),
        for (final p in players)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                NameToken(name: p.displayName, uid: p.uid, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.uid == game.hostUid
                        ? '${p.displayName} (host)'
                        : p.displayName,
                    style: AppText.body(14),
                  ),
                ),
                Text(
                  'online',
                  style: AppText.body(12, color: const Color(0xFF2E7D3A)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// 11c – end the game early.
class EndGameDialog extends StatelessWidget {
  const EndGameDialog({required this.game, super.key});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final left = [
      for (final p in game.prizes)
        if (!game.isWon(p.id)) p,
    ];
    final leftText = left.isEmpty
        ? 'Todos os prêmios de padrão já foram entregues.'
        : 'Ainda ${left.length == 1 ? 'falta 1 prêmio' : 'faltam ${left.length} prêmios'} '
              '(${left.map((p) => p.label).join(' e ')}). '
              '${left.length == 1 ? 'Ele não será entregue' : 'Eles não serão entregues'}.';
    return Dialog(
      backgroundColor: Colors.transparent,
      child: DialogCard(
        semanticLabel: 'Encerrar partida',
        maxWidth: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encerrar a partida agora?',
              style: AppText.display(32, color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            Text(
              '$leftText Se o azarão ainda não foi decidido, quem continua na disputa empata, e a seed é revelada para auditoria.',
              style: AppText.body(16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EAFA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text.rich(
                TextSpan(
                  style: AppText.body(14, color: const Color(0xFF5C2F86)),
                  children: const [
                    TextSpan(
                      text: 'Não dá para desfazer.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' A partida fica marcada como “encerrada pelo host”.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppButton(
                    label: 'Continuar jogando',
                    kind: AppButtonKind.outline,
                    height: 56,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  AppButton(
                    label: 'Encerrar partida',
                    kind: AppButtonKind.danger,
                    height: 56,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
