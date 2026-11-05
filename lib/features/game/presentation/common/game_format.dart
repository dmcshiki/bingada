import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/pattern_detector.dart';

/// Presentation-only formatting helpers shared by game, stream and result.
extension TemplateFormat on CardTemplate {
  Color columnColor(int column) => column < colors.length
      ? AppColors.parseHex(colors[column])
      : AppColors.columns[column % AppColors.columns.length];

  List<Color> get columnColors => [
    for (var c = 0; c < cols; c++) columnColor(c),
  ];

  String header(int column) => column < headers.length ? headers[column] : '';

  /// "N 38" (header + label).
  String ballText(ItemId id) => '${header(id.column)} ${item(id).label}'.trim();

  /// Compact "N38" for small tokens; long labels keep a space.
  String ballShort(ItemId id) {
    final label = item(id).label;
    return label.length > 3 ? label : '${header(id.column)}$label';
  }
}

/// Short explanation of a modality, as in the canvas.
String modalityHint(PatternKind kind) => switch (kind) {
  PatternKind.horizontal => 'uma linha inteira',
  PatternKind.vertical => 'uma coluna inteira',
  PatternKind.diagonal => 'uma das diagonais',
  PatternKind.line => 'linha, coluna ou diagonal',
  PatternKind.corners => 'os 4 cantos',
  PatternKind.x => 'as duas diagonais',
  PatternKind.frame => 'toda a borda',
  PatternKind.full => 'todas as células',
  PatternKind.custom => 'o desenho do host',
  PatternKind.underdog => 'último a sobrar: sai quem tem a bola sorteada',
};

String modalityName(Prize prize) => prize.pattern == PatternKind.custom
    ? (prize.customName ?? PatternKind.custom.label)
    : prize.pattern.label;

/// Joined description of matches, e.g. "Horizontal · linha 2".
String describeMatches(
  List<PatternMatch> matched,
  CardTemplate template, {
  Prize? prize,
}) {
  if (matched.isEmpty) return 'nenhum padrão completo';
  const detector = PatternDetector();
  return matched
      .map((m) => detector.describe(m, headers: template.headers, prize: prize))
      .join(' + ');
}

Prize? prizeById(Game game, PrizeId id) {
  for (final p in [...game.prizes, ...game.endOfGamePrizes]) {
    if (p.id == id) return p;
  }
  return null;
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

const List<Color> _avatarColors = [
  AppColors.primary,
  AppColors.navy,
  AppColors.deepBlue,
  AppColors.primaryStrong,
  AppColors.pink,
  AppColors.purple,
  AppColors.graphite,
];

/// Stable avatar color for a user.
Color avatarColor(UserId uid) {
  var h = 0;
  for (final c in uid.value.codeUnits) {
    h = (h * 31 + c) & 0x7FFFFFFF;
  }
  return _avatarColors[h % _avatarColors.length];
}

String playerName(List<Player> players, UserId uid) {
  for (final p in players) {
    if (p.uid == uid) return p.displayName;
  }
  return 'Jogador';
}

/// Deterministic stamp rotation (-10..10°) per cell (§8).
double stampRotation(int index, int cols) {
  final r = index ~/ cols;
  final c = index % cols;
  return ((r * 7 + c * 5) % 20 - 10).toDouble();
}

/// Ball number (1-based) for a claim/winner drawIndex (`draws.length`).
String ballOrdinal(int drawIndex) => 'bola $drawIndex';

/// Announces a message to screen readers in the current view.
Future<void> announce(BuildContext context, String message) async {
  final view = View.maybeOf(context);
  if (view == null) return;
  await SemanticsService.sendAnnouncement(
    view,
    message,
    Directionality.maybeOf(context) ?? TextDirection.ltr,
  );
}

/// Where a prize stands in the game (for prize lists).
enum PrizeStatus { won, open, waiting, underdog }

PrizeStatus prizeStatus(Game g, Prize p) {
  if (g.isWon(p.id)) return PrizeStatus.won;
  if (p.pattern == PatternKind.underdog) return PrizeStatus.underdog;
  if (g.openPrizes.any((o) => o.id == p.id)) return PrizeStatus.open;
  return PrizeStatus.waiting;
}

/// "Ana" / "Ana e Bia" / "Ana, Bia e Caio": who took [prize].
String winnerNames(Game g, Prize prize, List<Player> players) {
  final names = [
    for (final w in g.winnersOf(prize.id)) playerName(players, w.uid),
  ];
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
}

/// "Caneca (Horizontal) + Vale-café (Vertical)": everything open right now.
String openPrizesText(Game g) {
  final open = g.openPrizes;
  if (open.isEmpty) return '—';
  return open.map((p) => '${p.label} (${modalityName(p)})').join(' + ');
}
