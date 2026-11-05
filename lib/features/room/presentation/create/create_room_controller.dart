import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/data/dto/game_mapper.dart';
import 'package:tokingo/features/game/data/local/key_value_store.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/services.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';

enum AccessMode { domain, sameAsHost, allowlist, public }

enum ColumnKind { range, items }

/// Editable column of the template editor (04).
class ColumnDraft {
  ColumnDraft({
    required this.header,
    required this.color,
    this.kind = ColumnKind.range,
    this.content = '',
  });

  String header;
  String color;
  ColumnKind kind;

  /// "1 – 15" for ranges, comma-separated for items.
  String content;

  ColumnSource? toSource() {
    switch (kind) {
      case ColumnKind.range:
        final m = RegExp(r'^\s*(\d+)\s*[-–]\s*(\d+)\s*$').firstMatch(content);
        if (m == null) return null;
        final a = int.parse(m.group(1)!);
        final b = int.parse(m.group(2)!);
        if (b < a) return null;
        return ColumnSource.range(from: a, to: b);
      case ColumnKind.items:
        final items = content
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        return ColumnSource.items(items: items);
    }
  }

  int get itemCount => switch (toSource()) {
    RangeSource(:final from, :final to) => to - from + 1,
    ItemsSource(:final items) => items.length,
    null => 0,
  };
}

/// Editable sequential prize (05).
class PrizeDraft {
  PrizeDraft({required this.label, required this.pattern, this.winners = 1});

  String label;
  PatternKind pattern;
  int winners;
}

/// Matrix cell state for R30: winner of row → may compete for column.
enum AllowCell { notApplicable, allowed, denied }

enum CardPreset {
  classic('Clássico 75'),
  buzzwords('Buzzwords Dev'),
  blank('Em branco');

  CardPreset(this.label);
  final String label;
}

/// State of the create-room wizard (03–06). Pure-ish: domain calls via `sl`.
class CreateRoomController extends ChangeNotifier {
  CreateRoomController() {
    applyPreset(CardPreset.classic, notify: false);
  }

  static const stepLabels = ['Acesso', 'Cartela', 'Prêmios', 'Regras'];
  static const sizes = [5, 4, 3];
  static const limitOptions = <int?>[1, 2, 3, null];

  int step = 0;
  bool busy = false;

  // 03 Access
  String eventName = 'Happy hour de sexta';
  AccessMode mode = AccessMode.domain;
  String domainsText = '';
  String emailsText = '';

  // 04 Card
  CardPreset? preset = CardPreset.classic;
  String templateName = 'Clássico 75';
  int size = 5;
  bool freeEnabled = true;
  bool freeUseImage = false;
  String freeImageUrl = '';
  final columns = <ColumnDraft>[];
  int previewSeed = math.Random().nextInt(1 << 31);

  // 05 Prizes
  final prizes = <PrizeDraft>[
    PrizeDraft(label: 'Caneca', pattern: PatternKind.horizontal),
    PrizeDraft(label: 'Vale-café', pattern: PatternKind.vertical),
    PrizeDraft(label: 'Fone bluetooth', pattern: PatternKind.full),
  ];
  bool underdog = true;
  int? maxPerPlayer = 1;

  /// Key "r-c": r = index of the winner's prize, c = index among
  /// targets (sequential prizes after r, then underdog).
  final Map<String, bool> _allow = {};

  // 06 Rules
  bool hostPlays = true;
  bool showFailsOnStream = true;
  TieBreakRule tieBreak = TieBreakRule.draw;
  TieBreakRule underdogTie = TieBreakRule.draw;

  /// Skip N draws after a wrong claim; 0 = no penalty.
  int penaltyDraws = 0;

  AppUser? get user => sl<AuthRepository>().currentUser;

  String get hostDomain => user?.domain ?? '';

  void update(void Function() f) {
    f();
    notifyListeners();
  }

  void goTo(int s) => update(() => step = s.clamp(0, 3));

  // ---------- Access ----------

  List<String> get domains => domainsText
      .split(RegExp(r'[,\s;]+'))
      .map((d) => d.trim().toLowerCase().replaceFirst('@', ''))
      .where((d) => d.contains('.'))
      .toSet()
      .toList();

  List<String> get emails => emailsText
      .split(RegExp(r'[,\s;]+'))
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.contains('@'))
      .toSet()
      .toList();

  AccessPolicy get access => switch (mode) {
    AccessMode.domain => AccessPolicy.domain(domains: domains),
    AccessMode.sameAsHost => AccessPolicy.sameAsHost(hostDomain: hostDomain),
    AccessMode.allowlist => AccessPolicy.allowlist(emails: emails),
    AccessMode.public => const AccessPolicy.public(),
  };

  String? get accessError {
    if (eventName.trim().isEmpty) return 'Dê um nome ao evento.';
    return switch (mode) {
      AccessMode.domain when domains.isEmpty =>
        'Informe pelo menos um domínio.',
      AccessMode.sameAsHost when hostDomain.isEmpty =>
        'Não detectamos o domínio da sua conta.',
      AccessMode.allowlist when emails.isEmpty => 'Cole pelo menos um e-mail.',
      AccessMode.allowlist when emails.length > 60 => 'Máximo de 60 e-mails.',
      _ => null,
    };
  }

  String get accessSummary => switch (mode) {
    AccessMode.domain => 'Domínio: ${domains.join(', ')}',
    AccessMode.sameAsHost => 'Mesmo que o meu: $hostDomain',
    AccessMode.allowlist => 'Lista de e-mails: ${emails.length} convidados',
    AccessMode.public => 'Pública',
  };

  // ---------- Card ----------

  void applyPreset(CardPreset p, {bool notify = true}) {
    preset = p;
    templateName = p.label;
    size = 5;
    freeEnabled = true;
    freeUseImage = false;
    freeImageUrl = '';
    columns.clear();
    const letters = ['B', 'I', 'N', 'G', 'O'];
    const colors = ['#779ccf', '#09b5f0', '#4ec45f', '#c679cc', '#914ec4'];
    for (var c = 0; c < 5; c++) {
      columns.add(switch (p) {
        CardPreset.classic => ColumnDraft(
          header: letters[c],
          color: colors[c],
          content: '${c * 15 + 1} – ${c * 15 + 15}',
        ),
        CardPreset.buzzwords => ColumnDraft(
          header: letters[c],
          color: colors[c],
          kind: ColumnKind.items,
          content: _buzzwords[c].join(', '),
        ),
        CardPreset.blank => ColumnDraft(
          header: letters[c],
          color: colors[c],
          kind: ColumnKind.items,
        ),
      });
    }
    previewSeed = math.Random().nextInt(1 << 31);
    if (notify) notifyListeners();
  }

  static const _buzzwords = [
    [
      'Daily',
      'Sprint',
      'Refactor',
      'Hotfix',
      'Code review',
      'PR aprovado',
      'Merge conflict',
    ],
    [
      'Deploy na sexta',
      'Rollback',
      'Feature flag',
      'Pipeline vermelho',
      'Flaky test',
      'Débito técnico',
    ],
    [
      'Bug em prod',
      'Café',
      'Reunião que era e-mail',
      'Funciona na minha máquina',
      'Cache',
      'Timezone',
    ],
    [
      'Kubernetes',
      'Microsserviço',
      'Legado',
      'Stack Overflow',
      'Regex',
      'Docker',
    ],
    [
      'Retro',
      'Planning',
      'Estimativa',
      'Escopo',
      'Prazo',
      'MVP',
      'Stakeholder',
    ],
  ];

  void setSize(int s) => update(() {
    size = s;
    while (columns.length < s) {
      final i = columns.length;
      columns.add(
        ColumnDraft(
          header: String.fromCharCode(65 + i),
          color: const [
            '#779ccf',
            '#09b5f0',
            '#4ec45f',
            '#c679cc',
            '#914ec4',
          ][i % 5],
          kind: ColumnKind.items,
        ),
      );
    }
    preset = null;
  });

  List<ColumnDraft> get activeColumns => columns.take(size).toList();

  bool get freeAvailable => size.isOdd;

  /// Items needed in a column (the free column needs one less).
  int neededFor(int c) =>
      freeEnabled && freeAvailable && c == size ~/ 2 ? size - 1 : size;

  bool columnOk(int c) => columns[c].itemCount >= neededFor(c);

  CardTemplate? get template {
    final cols = activeColumns;
    final sources = <ColumnSource>[];
    for (final (i, c) in cols.indexed) {
      final s = c.toSource();
      if (s == null || !columnOk(i)) return null;
      sources.add(s);
    }
    return CardTemplate(
      name: templateName,
      rows: size,
      cols: size,
      headers: [
        for (final c in cols) c.header.trim().isEmpty ? '?' : c.header.trim(),
      ],
      colors: [for (final c in cols) c.color],
      free: FreeCell(
        enabled: freeEnabled && freeAvailable,
        imageUrl: freeUseImage && freeImageUrl.trim().isNotEmpty
            ? freeImageUrl.trim()
            : null,
      ),
      columns: sources,
    );
  }

  String? get cardError {
    if (template != null) return null;
    return 'Cada coluna precisa de pelo menos $size itens (o centro livre conta como um).';
  }

  void reshufflePreview() =>
      update(() => previewSeed = math.Random().nextInt(1 << 31));

  BingoCard? get previewCard {
    final t = template;
    if (t == null) return null;
    return sl<CardGenerator>().generate(
      uid: const UserId('preview'),
      gameId: GameId('preview-$previewSeed'),
      salt: '$previewSeed',
      template: t,
    );
  }

  String get cardSummary {
    final t = template;
    if (t == null) return '—';
    final free = t.freeCellIndex != null
        ? ' · centro livre ${t.free.label}'
        : '';
    return '$templateName · $size×$size$free · colunas ${t.headers.join(' ')}';
  }

  // ---------- Prizes ----------

  static List<PatternKind> get sequentialKinds =>
      PatternKind.values.where((k) => k != PatternKind.underdog).toList();

  void addPrize() => update(() {
    prizes.add(PrizeDraft(label: '', pattern: PatternKind.horizontal));
    _resetAllow();
  });

  void removePrize(int i) => update(() {
    if (prizes.length > 1) prizes.removeAt(i);
    _resetAllow();
  });

  void setLimit(int? v) => update(() {
    maxPerPlayer = v;
    _resetAllow();
  });

  void setUnderdog(bool v) => update(() {
    underdog = v;
    _resetAllow();
  });

  void _resetAllow() {
    _allow.clear();
  }

  /// Rows: every sequential prize (winner of row r).
  List<int> get matrixRows => [for (var i = 0; i < prizes.length; i++) i];

  /// Column titles: sequential prizes 2..n, then "Azarão" if active.
  List<String> get matrixCols => [
    for (var i = 1; i < prizes.length; i++)
      '${i + 1} ${_short(prizes[i].label)}',
    if (underdog) 'Azarão',
  ];

  static String _short(String label) {
    final l = label.trim();
    if (l.isEmpty) return 'Prêmio';
    return l.split(' ').first;
  }

  String rowLabel(int r) => '${r + 1} ${_short(prizes[r].label)}';

  bool isUnderdogCol(int c) => c >= prizes.length - 1;

  /// Column c is sequential prize index c+1, or the underdog when beyond.
  /// A winner can only compete for later prizes: earlier/same is "—".
  AllowCell cell(int r, int c) {
    if (!isUnderdogCol(c) && c < r) return AllowCell.notApplicable;
    final v = _allow['$r-$c'] ?? (maxPerPlayer != 1);
    return v ? AllowCell.allowed : AllowCell.denied;
  }

  void toggle(int r, int c) {
    final s = cell(r, c);
    if (s == AllowCell.notApplicable) return;
    update(() => _allow['$r-$c'] = s != AllowCell.allowed);
  }

  String get limitHelp => maxPerPlayer == 1
      ? 'Com 1 prêmio por pessoa, quem ganha sai da disputa dos próximos.'
      : 'Ajuste caso a caso na tabela.';

  String? get prizesError {
    if (prizes.isEmpty) return 'Adicione pelo menos um prêmio.';
    if (prizes.any((p) => p.label.trim().isEmpty)) {
      return 'Dê um nome a cada prêmio.';
    }
    if (prizes.any((p) => p.winners < 1)) {
      return 'Cada prêmio precisa de pelo menos 1 vencedor.';
    }
    return null;
  }

  List<Prize> get builtPrizes => [
    for (final (i, p) in prizes.indexed)
      Prize(
        id: PrizeId('p${i + 1}'),
        label: p.label.trim(),
        pattern: p.pattern,
        winners: p.winners,
        order: i + 1,
      ),
  ];

  List<Prize> get builtEndPrizes => [
    if (underdog)
      const Prize(
        id: PrizeId('u1'),
        label: 'Prêmio azarão',
        pattern: PatternKind.underdog,
      ),
  ];

  PrizePolicy get prizePolicy {
    final cols = matrixCols.length;
    final allow = <PrizeId, List<PrizeId>>{
      for (var r = 0; r < prizes.length; r++)
        PrizeId('p${r + 1}'): [
          for (var c = 0; c < cols; c++)
            if (cell(r, c) == AllowCell.allowed)
              isUnderdogCol(c) ? const PrizeId('u1') : PrizeId('p${c + 2}'),
        ],
    };
    return PrizePolicy(maxPerPlayer: maxPerPlayer, allow: allow);
  }

  String get prizesSummary {
    final parts = [
      for (final (i, p) in prizes.indexed)
        '${i + 1} ${p.label} (${p.pattern.label}${i == prizes.length - 1 ? ', encerra o jogo' : ''})',
    ];
    return parts.join(' → ');
  }

  // ---------- Submit ----------

  String? errorForStep(int s) => switch (s) {
    0 => accessError,
    1 => cardError,
    2 => prizesError,
    _ => null,
  };

  CreateGameInput buildInput() => CreateGameInput(
    eventName: eventName.trim(),
    access: access,
    template: template!,
    prizes: builtPrizes,
    endOfGamePrizes: builtEndPrizes,
    prizePolicy: prizePolicy,
    settings: GameSettings(
      hostPlays: hostPlays,
      showFailsOnStream: showFailsOnStream,
      tieBreak: tieBreak,
      underdogTieBreak: underdogTie,
      claimPenalty: penaltyDraws > 0
          ? ClaimPenaltyPolicy.skipDraws(draws: penaltyDraws)
          : const ClaimPenaltyPolicy.none(),
    ),
  );

  Future<Game> submit() async {
    final u = user;
    if (u == null) throw StateError('not signed in');
    busy = true;
    notifyListeners();
    try {
      return await sl<CreateGame>()(u, buildInput());
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------- Templates (import / save) ----------

  static const _templatesKey = 'tokingo.cardTemplates';
  static const _mapper = GameMapper();

  KeyValueStore get _kv => sl.isRegistered<KeyValueStore>()
      ? sl<KeyValueStore>()
      : (_memoryKv ??= KeyValueStore.memory());
  static KeyValueStore? _memoryKv;

  /// Loads a template into the editor (04).
  void loadTemplate(CardTemplate t, {bool notify = true}) {
    preset = null;
    templateName = t.name;
    size = sizes.contains(t.cols) ? t.cols : 5;
    freeEnabled = t.free.enabled;
    freeImageUrl = t.free.imageUrl ?? '';
    freeUseImage = freeImageUrl.isNotEmpty;
    columns.clear();
    for (var c = 0; c < t.columns.length; c++) {
      final src = t.columns[c];
      columns.add(
        ColumnDraft(
          header: c < t.headers.length ? t.headers[c] : '?',
          color: c < t.colors.length ? t.colors[c] : '#779ccf',
          kind: src is RangeSource ? ColumnKind.range : ColumnKind.items,
          content: switch (src) {
            RangeSource(:final from, :final to) => '$from – $to',
            ItemsSource(:final items) => items.join(', '),
          },
        ),
      );
    }
    previewSeed = math.Random().nextInt(1 << 31);
    if (notify) notifyListeners();
  }

  /// Parses a template JSON (same shape as the stored game template).
  /// Returns an error message, or null on success.
  String? importJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 'O JSON precisa ser um objeto.';
      final t = _mapper.templateFromMap(decoded.cast<String, Object?>());
      if (t.columns.isEmpty) return 'O modelo não tem colunas.';
      loadTemplate(t);
      return null;
    } on Object catch (e) {
      return 'JSON inválido: $e';
    }
  }

  /// Saved templates (local storage), newest last.
  List<CardTemplate> get savedTemplates {
    final raw = _kv.read(_templatesKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final m in list)
          _mapper.templateFromMap((m as Map).cast<String, Object?>()),
      ];
    } on Object {
      return const [];
    }
  }

  /// Saves the current template locally (replaces one with the same name).
  /// Returns an error message, or null on success.
  String? saveAsTemplate() {
    final t = template;
    if (t == null) return cardError;
    final list = [
      for (final s in savedTemplates)
        if (s.name != t.name) s,
      t,
    ];
    _kv.write(
      _templatesKey,
      jsonEncode([for (final s in list) _mapper.templateToMap(s)]),
    );
    notifyListeners();
    return null;
  }

  // ---------- Prefill ("Novo jogo") ----------

  /// Copies the configuration of a previous game into the wizard.
  void prefillFrom(Game g) {
    eventName = g.eventName;
    switch (g.access) {
      case DomainAccess(:final domains):
        mode = AccessMode.domain;
        domainsText = domains.join(', ');
      case SameAsHostAccess():
        mode = AccessMode.sameAsHost;
      case AllowlistAccess(:final emails):
        mode = AccessMode.allowlist;
        emailsText = emails.join('\n');
      case PublicAccess():
        mode = AccessMode.public;
    }
    loadTemplate(g.template, notify: false);
    preset = CardPreset.values
        .where((p) => p.label == g.template.name)
        .firstOrNull;
    prizes
      ..clear()
      ..addAll([
        for (final p in g.prizes)
          PrizeDraft(label: p.label, pattern: p.pattern, winners: p.winners),
      ]);
    if (prizes.isEmpty) {
      prizes.add(PrizeDraft(label: '', pattern: PatternKind.horizontal));
    }
    underdog = g.endOfGamePrizes.any((p) => p.pattern == PatternKind.underdog);
    maxPerPlayer = g.prizePolicy.maxPerPlayer;
    _allow.clear();
    for (var r = 0; r < prizes.length; r++) {
      final allowed = g.prizePolicy.allow[PrizeId('p${r + 1}')];
      if (allowed == null) continue;
      for (var c = 0; c < matrixCols.length; c++) {
        if (cell(r, c) == AllowCell.notApplicable) continue;
        final target = isUnderdogCol(c)
            ? const PrizeId('u1')
            : PrizeId('p${c + 2}');
        _allow['$r-$c'] = allowed.contains(target);
      }
    }
    hostPlays = g.settings.hostPlays;
    showFailsOnStream = g.settings.showFailsOnStream;
    tieBreak = g.settings.tieBreak;
    underdogTie = g.settings.underdogTie;
    penaltyDraws = switch (g.settings.claimPenalty) {
      SkipDraws(:final draws) => draws,
      NoPenalty() => 0,
    };
    notifyListeners();
  }
}
