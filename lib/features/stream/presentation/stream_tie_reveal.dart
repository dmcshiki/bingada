import 'package:flutter/material.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/tie_player_card.dart';
import 'package:tokingo/features/stream/presentation/stream_fx.dart';

/// Tie cards on the stream. While [winners] is null the cards wait; once it is
/// set they play a reveal: a highlight hops between cards (slowing down),
/// lands on the winner, which scales up with a token burst while the losers
/// fade. [onRevealed] fires when the reveal ends (immediately with reduced
/// motion, which only cross-fades).
class TieReveal extends StatefulWidget {
  const TieReveal({
    required this.tied,
    required this.players,
    required this.winnerTag,
    required this.winners,
    super.key,
    this.how,
    this.onRevealed,
  });

  final List<UserId> tied;
  final List<Player> players;
  final String winnerTag;
  final Set<UserId>? winners;
  final String? how;
  final VoidCallback? onRevealed;

  @override
  State<TieReveal> createState() => _TieRevealState();
}

class _TieRevealState extends State<TieReveal>
    with SingleTickerProviderStateMixin {
  static const _shuffleEnd = .7;

  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..addStatusListener(_onStatus);
  bool _started = false;

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) widget.onRevealed?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(TieReveal old) {
    super.didUpdateWidget(old);
    _maybeStart();
  }

  void _maybeStart() {
    if (_started || widget.winners == null) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _a.value = 1;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onRevealed?.call(),
      );
    } else {
      _a.forward();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  /// Card highlighted during the shuffle: hops fast, then slows down and
  /// always ends on a winner.
  int _hop(double t) {
    final n = widget.tied.length;
    final w = widget.winners ?? const <UserId>{};
    final target = widget.tied.indexWhere(w.contains);
    final p = (t / _shuffleEnd).clamp(0.0, 1.0);
    // Ease-out on the hop count: many hops early, few late.
    final hops = 3 * n + (target < 0 ? 0 : target);
    final step = (Curves.easeOutCubic.transform(p) * hops).floor();
    return step % n;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final t = _a.value;
        final w = widget.winners;
        final revealed = w != null && t >= _shuffleEnd;
        final settle = revealed
            ? Curves.easeOutBack.transform(
                ((t - _shuffleEnd) / (1 - _shuffleEnd)).clamp(0.0, 1.0),
              )
            : 0.0;
        final hop = w != null && !revealed ? _hop(t) : -1;
        return Wrap(
          spacing: 56,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            for (final (i, uid) in widget.tied.indexed)
              _card(
                uid: uid,
                state: !revealed
                    ? TieCardState.pending
                    : w.contains(uid)
                    ? TieCardState.winner
                    : TieCardState.loser,
                highlighted: i == hop,
                settle: reduce ? 1 : settle,
                reduce: reduce,
              ),
          ],
        );
      },
    );
  }

  Widget _card({
    required UserId uid,
    required TieCardState state,
    required bool highlighted,
    required double settle,
    required bool reduce,
  }) {
    final card = TiePlayerCard(
      name: playerName(widget.players, uid),
      uid: uid,
      width: 400,
      how: widget.how,
      winnerTag: widget.winnerTag,
      state: state,
    );
    final scale = switch (state) {
      TieCardState.winner => reduce ? 1.0 : 1 + .12 * settle,
      TieCardState.loser => reduce ? 1.0 : 1 - .06 * settle,
      TieCardState.pending => highlighted ? 1.08 : 1.0,
    };
    final opacity = switch (state) {
      TieCardState.loser => 1 - .55 * settle.clamp(0.0, 1.0),
      TieCardState.pending => highlighted || widget.winners == null ? 1.0 : .7,
      TieCardState.winner => 1.0,
    };
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: Duration(milliseconds: reduce ? 200 : 120),
          opacity: opacity,
          child: Transform.scale(scale: scale, child: card),
        ),
        if (state == TieCardState.winner && !reduce)
          const Positioned.fill(child: TokenBurst(radius: 360, count: 32)),
      ],
    );
  }
}
