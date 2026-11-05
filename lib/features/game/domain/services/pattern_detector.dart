import 'package:tokingo/features/game/domain/entities/prize.dart';

/// Finds which patterns are complete given filled cells (row-major indexes;
/// the free cell must already be included by the caller).
final class PatternDetector {
  const PatternDetector();

  List<PatternMatch> completed({
    required Set<int> filled,
    required int rows,
    required int cols,
    required Prize prize,
  }) {
    bool all(Iterable<int> cells) => cells.every(filled.contains);
    final square = rows == cols;
    final main = [for (var i = 0; i < rows; i++) i * cols + i];
    final anti = [for (var i = 0; i < rows; i++) i * cols + (cols - 1 - i)];

    List<PatternMatch> horizontal() => [
      for (var r = 0; r < rows; r++)
        if (all([for (var c = 0; c < cols; c++) r * cols + c]))
          PatternMatch(kind: PatternKind.horizontal, index: r),
    ];
    List<PatternMatch> vertical() => [
      for (var c = 0; c < cols; c++)
        if (all([for (var r = 0; r < rows; r++) r * cols + c]))
          PatternMatch(kind: PatternKind.vertical, index: c),
    ];
    List<PatternMatch> diagonal() => [
      if (square && all(main)) const PatternMatch(kind: PatternKind.diagonal),
      if (square && all(anti))
        const PatternMatch(kind: PatternKind.diagonal, index: 1),
    ];
    List<PatternMatch> single(PatternKind k, {required bool ok}) => [
      if (ok) PatternMatch(kind: k),
    ];

    final total = rows * cols;
    return switch (prize.pattern) {
      PatternKind.horizontal => horizontal(),
      PatternKind.vertical => vertical(),
      PatternKind.diagonal => diagonal(),
      PatternKind.line => [...horizontal(), ...vertical(), ...diagonal()],
      PatternKind.corners => single(
        PatternKind.corners,
        ok: all([0, cols - 1, (rows - 1) * cols, total - 1]),
      ),
      PatternKind.x => single(
        PatternKind.x,
        ok: square && all(main) && all(anti),
      ),
      PatternKind.frame => single(
        PatternKind.frame,
        ok: all([
          for (var i = 0; i < total; i++)
            if (i < cols ||
                i >= total - cols ||
                i % cols == 0 ||
                i % cols == cols - 1)
              i,
        ]),
      ),
      PatternKind.full => single(
        PatternKind.full,
        ok: all([for (var i = 0; i < total; i++) i]),
      ),
      PatternKind.custom => single(
        PatternKind.custom,
        ok: switch (prize.customMask) {
          final m? when m.contains(true) => all([
            for (final (i, on) in m.indexed)
              if (on) i,
          ]),
          _ => false,
        },
      ),
      PatternKind.underdog => const [],
    };
  }

  /// Human label, e.g. "Horizontal · linha 2", "Vertical · coluna G".
  String describe(
    PatternMatch match, {
    required List<String> headers,
    Prize? prize,
  }) => switch (match.kind) {
    PatternKind.horizontal => 'Horizontal · linha ${match.index + 1}',
    PatternKind.vertical =>
      'Vertical · coluna ${match.index < headers.length ? headers[match.index] : match.index + 1}',
    PatternKind.diagonal => match.index == 0 ? 'Diagonal ↘' : 'Diagonal ↙',
    PatternKind.custom => prize?.customName ?? 'Customizado',
    final k => k.label,
  };
}
