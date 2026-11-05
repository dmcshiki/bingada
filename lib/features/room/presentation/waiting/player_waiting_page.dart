import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/help/presentation/how_to_play.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';
import 'package:tokingo/features/room/presentation/waiting/room_watch_controller.dart';

/// 08 – Sala de espera do jogador. Navigates to play/result on status change.
class PlayerWaitingPage extends StatefulWidget {
  const PlayerWaitingPage({required this.code, super.key});

  final RoomCode code;

  @override
  State<PlayerWaitingPage> createState() => _PlayerWaitingPageState();
}

class _PlayerWaitingPageState extends State<PlayerWaitingPage> {
  late final _c = RoomWatchController(widget.code)
    ..addListener(_onChange)
    ..load();
  bool _left = false;

  @override
  void dispose() {
    _c
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  void _onChange() {
    if (_left || !mounted) return;
    if (_c.notFound) {
      _left = true;
      context.go(AppRoutes.error(ErrorKinds.invalidCode, code: widget.code));
      return;
    }
    final target = switch (_c.game?.status) {
      GameStatus.running => AppRoutes.play(widget.code),
      GameStatus.finished ||
      GameStatus.abandoned => AppRoutes.result(widget.code),
      _ => null,
    };
    if (target != null) {
      _left = true;
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final g = _c.game;
      if (g == null) return const LoadingView();
      final narrow = isNarrow(context);
      final name =
          sl<AuthRepository>().currentUser?.displayName.split(' ').first ?? '';
      final info = _Info(game: g, name: name, narrow: narrow);
      final card = _BlurredCard(
        cols: g.template.cols,
        rows: g.template.rows,
        colors: g.template.colors,
      );
      return AppPage(
        blobs: const [
          Positioned(
            right: -180,
            top: -220,
            child: BlobShape(size: 560, color: AppColors.primary),
          ),
        ],
        child: Column(
          children: [
            _Header(game: g),
            Expanded(
              child: SingleChildScrollView(
                padding: narrow
                    ? const EdgeInsets.fromLTRB(16, 16, 16, 32)
                    : const EdgeInsets.fromLTRB(80, 24, 80, 48),
                child: narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [info, const SizedBox(height: 24), card],
                      )
                    : Row(
                        children: [
                          Expanded(child: info),
                          const SizedBox(width: 40),
                          SizedBox(width: 520, child: card),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return SizedBox(
      height: 72,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 40),
        child: Row(
          children: [
            const Wordmark(),
            const SizedBox(width: 24),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AppText.body(16, weight: FontWeight.w300),
                  children: [
                    TextSpan(
                      text: narrow ? 'sala ' : '${game.eventName} · sala ',
                    ),
                    TextSpan(
                      text: game.roomCode.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            HelpButton(onPressed: () => showHowToPlaySheet(context)),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.game, required this.name, required this.narrow});

  final Game game;
  final String name;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final line = AppText.body(15);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              style: AppText.body(
                narrow ? 38 : 52,
                weight: FontWeight.w300,
                height: 1.1,
              ),
              children: [
                const TextSpan(text: 'tudo pronto,\n'),
                TextSpan(
                  text: name.isEmpty ? 'jogador!' : '$name!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Sua cartela já foi gerada e é só sua: abra em outro dispositivo e ela continua igual. Aguarde o host começar. Quem não entrar até lá fica de fora desta partida.',
            style: AppText.body(18, height: 1.5),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Chip(
              child: Text.rich(
                TextSpan(
                  style: line,
                  children: [
                    TextSpan(
                      text: '${game.playerCount}/${game.maxPlayers}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' jogadores'),
                  ],
                ),
              ),
            ),
            _Chip(child: Text('Sala fecha quando o jogo começar', style: line)),
          ],
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SectionCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÊMIOS DA NOITE',
                  style: AppText.body(
                    13,
                    weight: FontWeight.w700,
                    letterSpacing: .65,
                  ),
                ),
                // R23: no "(encerra o jogo)" and no "1º prêmio" marker.
                // Azarão first, pattern prizes together, full card last.
                for (final (i, p) in game.displayPrizes.indexed) ...[
                  const SizedBox(height: 8),
                  Text('${i + 1} ${p.label} · ${p.pattern.label}', style: line),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: child,
    ),
  );
}

class _BlurredCard extends StatelessWidget {
  const _BlurredCard({
    required this.cols,
    required this.rows,
    required this.colors,
  });

  final int cols;
  final int rows;
  final List<String> colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
      padding: const EdgeInsets.all(22),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: Opacity(
              opacity: .7,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Column(
                  children: [
                    for (var r = 0; r < rows; r++) ...[
                      if (r > 0) const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var c = 0; c < cols; c++) ...[
                            if (c > 0) const SizedBox(width: 10),
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: r == 0
                                        ? AppColors.parseHex(
                                            colors[c % colors.length],
                                          )
                                        : AppColors.light,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Sua cartela aparece quando o jogo começar',
              textAlign: TextAlign.center,
              style: AppText.body(
                16,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
