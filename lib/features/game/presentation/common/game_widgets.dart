import 'package:flutter/material.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';

/// Current ball inside the tilted token (§8). Enters with `easeOutBack`,
/// or a plain fade when the platform asks to disable animations.
class BallToken extends StatelessWidget {
  const BallToken({
    required this.template,
    required this.ball,
    required this.size,
    super.key,
    this.shadow = true,
  });

  final CardTemplate template;
  final ItemId? ball;
  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final id = ball;
    final token = TokenBox(
      key: ValueKey(id?.value ?? 'none'),
      size: size,
      // Same color as the ball's column (B I N G O headers).
      color: id == null ? AppColors.light : template.columnColor(id.column),
      radiusFactor: .255,
      shadow: shadow,
      child: id == null
          ? Text(
              '–',
              style: AppText.display(size * .4, color: AppColors.graphite),
            )
          : _BallLabel(template: template, id: id, size: size),
    );
    return Semantics(
      liveRegion: true,
      label: id == null
          ? 'Nenhuma bola sorteada ainda'
          : 'Bola atual ${template.ballText(id)}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size * 1.15,
          height: size * 1.15,
          child: Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: reduce ? 150 : 420),
              switchInCurve: reduce ? Curves.linear : Curves.easeOutBack,
              transitionBuilder: (child, anim) => reduce
                  ? FadeTransition(opacity: anim, child: child)
                  : ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
              child: token,
            ),
          ),
        ),
      ),
    );
  }
}

class _BallLabel extends StatelessWidget {
  const _BallLabel({
    required this.template,
    required this.id,
    required this.size,
  });

  final CardTemplate template;
  final ItemId id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = template.item(id).label;
    final long = label.length > 3;
    final fg = AppColors.onColor(template.columnColor(id.column));
    return Padding(
      padding: EdgeInsets.all(size * .06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            template.header(id.column),
            style: AppText.display(size * .17, color: fg),
          ),
          FittedBox(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppText.display(
                long ? size * .16 : size * .5,
                color: fg,
              ).copyWith(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Table of the whole pool by column with drawn balls lit (host / stream).
class PoolBoard extends StatelessWidget {
  const PoolBoard({
    required this.template,
    required this.drawn,
    super.key,
    this.current,
    this.dark = false,
    this.cellHeight = 30,
    this.perRow = 8,
  });

  final CardTemplate template;
  final Set<ItemId> drawn;
  final ItemId? current;
  final bool dark;
  final double cellHeight;
  final int perRow;

  @override
  Widget build(BuildContext context) {
    final gap = cellHeight * .13;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var c = 0; c < template.columns.length; c++)
          Padding(
            padding: EdgeInsets.only(bottom: gap * 2),
            child: _BoardRow(
              template: template,
              column: c,
              drawn: drawn,
              current: current,
              dark: dark,
              cellHeight: cellHeight,
              perRow: perRow,
              gap: gap,
            ),
          ),
      ],
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.template,
    required this.column,
    required this.drawn,
    required this.current,
    required this.dark,
    required this.cellHeight,
    required this.perRow,
    required this.gap,
  });

  final CardTemplate template;
  final int column;
  final Set<ItemId> drawn;
  final ItemId? current;
  final bool dark;
  final double cellHeight;
  final int perRow;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final color = template.columnColor(column);
    final fg = AppColors.onColor(color);
    final labels = template.labelsOf(column);
    final drawnLabels = [
      for (final (i, l) in labels.indexed)
        if (drawn.contains(ItemId.of(column, i))) l,
    ];
    return Semantics(
      label:
          'Coluna ${template.header(column)}: ${drawnLabels.isEmpty ? 'nenhuma sorteada' : 'sorteadas ${drawnLabels.join(', ')}'}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: cellHeight,
              height: cellHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(cellHeight * .32),
              ),
              child: Text(
                template.header(column),
                style: AppText.display(cellHeight * .5, color: fg),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = (box.maxWidth - gap * (perRow - 1)) / perRow;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final (i, label) in labels.indexed)
                        _BoardCell(
                          width: w,
                          height: cellHeight,
                          label: label,
                          lit: drawn.contains(ItemId.of(column, i)),
                          isCurrent: current == ItemId.of(column, i),
                          color: color,
                          dark: dark,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.width,
    required this.height,
    required this.label,
    required this.lit,
    required this.isCurrent,
    required this.color,
    required this.dark,
  });

  final double width;
  final double height;
  final String label;
  final bool lit;
  final bool isCurrent;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // Current ball keeps its column color (cyan looked like the O column)
    // and is marked by a ring instead.
    final bg = isCurrent || lit
        ? color
        : dark
        ? AppColors.white.withValues(alpha: .10)
        : AppColors.light;
    final fg = isCurrent || lit
        ? AppColors.onColor(bg)
        : dark
        ? const Color(0xFFB8C7DC)
        : const Color(0xFF6B6869);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height * .27),
        border: isCurrent
            ? Border.all(
                color: dark ? AppColors.white : AppColors.graphite,
                width: 3,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          child: Text(
            label,
            maxLines: 1,
            style: AppText.display(height * .4, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Dimmed full-screen scrim hosting a centered dialog card.
class ScrimOverlay extends StatelessWidget {
  const ScrimOverlay({
    required this.child,
    super.key,
    this.color = const Color(0x8C424041),
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: color,
      child: SafeArea(
        child: Align(
          alignment: alignment,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// White rounded dialog card with a max width.
class DialogCard extends StatelessWidget {
  const DialogCard({
    required this.child,
    required this.semanticLabel,
    super.key,
    this.maxWidth = 620,
    this.padding = const EdgeInsets.all(40),
    this.color = AppColors.white,
  });

  final Widget child;
  final String semanticLabel;
  final double maxWidth;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    scopesRoute: true,
    namesRoute: true,
    explicitChildNodes: true,
    label: semanticLabel,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SectionCard(
        radius: 32,
        color: color,
        padding: MediaQuery.sizeOf(context).width < 600
            ? const EdgeInsets.all(24)
            : padding,
        child: child,
      ),
    ),
  );
}

/// Simple centered loading / error placeholder.
class GameLoadingView extends StatelessWidget {
  const GameLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.light,
    body: Center(
      child: message == null
          ? const TokenLoader(label: 'Carregando a partida…')
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: AppText.body(18, color: AppColors.graphite),
              ),
            ),
    ),
  );
}

/// Profile photos by player uid, filled whenever a players list arrives, so
/// every avatar can show the Google photo without threading it everywhere.
final Map<UserId, String> playerPhotos = {};

void rememberPlayerPhotos(Iterable<Player> players) {
  for (final p in players) {
    final url = p.photoUrl;
    if (url != null && url.isNotEmpty) playerPhotos[p.uid] = url;
  }
}

/// Fixed-size avatar token with initials of [name].
class NameToken extends StatelessWidget {
  const NameToken({
    required this.name,
    required this.uid,
    required this.size,
    super.key,
  });

  final String name;
  final UserId uid;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size * 1.1,
      height: size * 1.1,
      child: Center(
        child: AvatarToken(
          initials: initialsOf(name),
          size: size,
          color: avatarColor(uid),
          photoUrl: playerPhotos[uid],
        ),
      ),
    ),
  );
}
