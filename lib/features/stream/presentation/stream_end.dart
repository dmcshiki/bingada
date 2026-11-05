import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/result/presentation/result_page.dart';

/// End screen of the stream: same look as the players' result page (14),
/// reusing [ResultView], with a confetti blast of tokens on entry.
class StreamEnd extends StatefulWidget {
  const StreamEnd({
    required this.game,
    required this.players,
    required this.claims,
    super.key,
    this.chroma = false,
  });

  final Game game;
  final List<Player> players;
  final List<Claim> claims;
  final bool chroma;

  @override
  State<StreamEnd> createState() => _StreamEndState();
}

class _StreamEndState extends State<StreamEnd> {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 4),
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played || MediaQuery.disableAnimationsOf(context)) return;
    _played = true;
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (!widget.chroma)
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
        child: ResultView(
          game: widget.game,
          players: widget.players,
          claims: widget.claims,
          cards: const [],
          isHost: false,
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
  );
}

Path _tokenPath(Size size) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * .28),
    ),
  );
