import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tokingo/core/config/app_config.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/audit/data/browser_io.dart';
import 'package:tokingo/features/game/data/dto/game_mapper.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/audit_service.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';

/// Loads public data and runs [AuditService] in the browser.
class AuditController extends ChangeNotifier {
  AuditController({
    required this.gameId,
    required GameRepository repository,
    required this._service,
  }) : _repo = repository;

  final GameId gameId;
  final GameRepository _repo;
  final AuditService _service;

  bool loading = true;
  String? error;
  Game? game;
  List<BingoCard> cards = const [];
  List<Claim> claims = const [];
  List<AuditCheck> checks = const [];
  bool _disposed = false;

  Future<void> run() async {
    try {
      final g = await _repo.getGame(gameId);
      if (g == null) {
        error = 'Partida não encontrada.';
        return;
      }
      game = g;
      cards = await _repo.getCards(gameId);
      claims = await _repo
          .watchClaims(gameId)
          .first
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => const <Claim>[],
          );
      checks = _service.audit(game: g, cards: cards, claims: claims);
    } on Object catch (e) {
      error = 'Não deu para auditar: $e';
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Everything the audit used (game, cards, claims) plus the results, as
  /// pretty JSON. Null until loaded.
  String? exportJson() {
    final g = game;
    if (g == null) return null;
    const m = GameMapper();
    return const JsonEncoder.withIndent('  ').convert({
      'gameId': gameId.value,
      'build': kGitSha,
      'game': m.gameToMap(g),
      'cards': [for (final c in cards) m.cardToMap(c)],
      'claims': [for (final c in claims) m.claimToMap(c)],
      'checks': [
        for (final c in checks)
          {
            'title': c.title,
            'detail': c.detail,
            'result': c.result,
            'ok': c.ok,
          },
      ],
    });
  }

  bool get allOk => checks.isNotEmpty && checks.every((c) => c.ok);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// 16 – public audit.
class AuditPage extends StatefulWidget {
  const AuditPage({required this.gameId, super.key});

  final GameId gameId;

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  late final AuditController _c;

  @override
  void initState() {
    super.initState();
    _c = AuditController(
      gameId: widget.gameId,
      repository: sl<GameRepository>(),
      service: sl.isRegistered<AuditService>()
          ? sl<AuditService>()
          : const AuditService(),
    );
    unawaited(_c.run());
  }

  late final TapGestureRecognizer _linkTap = TapGestureRecognizer()
    ..onTap = () => openExternal(kCommitUrl);

  @override
  void dispose() {
    _linkTap.dispose();
    _c.dispose();
    super.dispose();
  }

  String get _shortId {
    final v = widget.gameId.value;
    return v.length > 10
        ? '${v.substring(0, 6)}…${v.substring(v.length - 3)}'
        : v;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final narrow = MediaQuery.sizeOf(context).width < 900;
      final pad = narrow ? 16.0 : 40.0;
      return Scaffold(
        backgroundColor: AppColors.light,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 72),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: pad,
                  vertical: narrow ? 12 : 0,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    Wrap(
                      spacing: 24,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Wordmark(),
                        Text.rich(
                          TextSpan(
                            style: AppText.body(16, weight: FontWeight.w300),
                            children: [
                              const TextSpan(text: 'auditoria '),
                              const TextSpan(
                                text: 'pública',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: ' · jogo '),
                              TextSpan(text: _shortId, style: AppText.mono(15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text.rich(
                      TextSpan(
                        style: AppText.body(13),
                        children: [
                          const TextSpan(text: 'build '),
                          TextSpan(text: kGitSha, style: AppText.mono(13)),
                          const TextSpan(text: ' · '),
                          TextSpan(
                            text: 'código no GitHub ↗',
                            style: const TextStyle(color: AppColors.navy),
                            recognizer: _linkTap,
                            semanticsLabel: 'Abrir o código no GitHub',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _c.loading
                    ? const Center(
                        child: TokenLoader(label: 'Recalculando a partida…'),
                      )
                    : _c.error != null
                    ? GameLoadingView(message: _c.error)
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
                        child: Flex(
                          direction: narrow ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: narrow ? double.infinity : 460,
                              child: _Seal(controller: _c),
                            ),
                            const SizedBox(width: 24, height: 24),
                            if (narrow)
                              _ChecksList(checks: _c.checks)
                            else
                              Expanded(child: _ChecksList(checks: _c.checks)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Seal extends StatelessWidget {
  const _Seal({required this.controller});

  final AuditController controller;

  @override
  Widget build(BuildContext context) {
    final ok = controller.allOk;
    final failing = [
      for (final c in controller.checks)
        if (!c.ok) c,
    ];
    final bg = ok ? AppColors.greenDark : AppColors.purple;
    return Semantics(
      liveRegion: true,
      child: SectionCard(
        color: bg,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TokenBox(
                size: 140,
                color: AppColors.white,
                child: Text(
                  ok ? '✓' : '!',
                  style: AppText.display(72, color: bg),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              ok ? 'Partida 100% verificada' : 'Divergências encontradas',
              style: AppText.display(
                32,
                color: AppColors.white,
              ).copyWith(height: 1.15),
            ),
            const SizedBox(height: 18),
            if (ok)
              Text(
                'Tudo foi recalculado agora, no seu navegador, com o mesmo código aberto que '
                'rodou na partida. Nada depende de confiar no host.',
                style: AppText.body(15, color: AppColors.white, height: 1.5),
              )
            else
              for (final f in failing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '✕ ${f.title}: ${f.result}',
                    style: AppText.body(
                      15,
                      color: AppColors.white,
                      height: 1.4,
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  final json = controller.exportJson();
                  if (json == null ||
                      !downloadTextFile(
                        'tokingo-${controller.gameId.value}.json',
                        json,
                      )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download disponível só no navegador.'),
                      ),
                    );
                  }
                },
                child: Text(
                  'Baixar dados da partida (JSON)',
                  style: AppText.body(
                    15,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecksList extends StatelessWidget {
  const _ChecksList({required this.checks});

  final List<AuditCheck> checks;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SplitTitle('o que foi', 'conferido', size: 24),
        const SizedBox(height: 18),
        for (final c in checks) ...[
          _CheckTile(check: c),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.check});

  final AuditCheck check;

  @override
  Widget build(BuildContext context) {
    final ok = check.ok;
    return Semantics(
      label: '${check.title}: ${ok ? 'ok' : 'falhou'}, ${check.result}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ok ? AppColors.surfaceSoft : const Color(0xFFF3EAFA),
            borderRadius: BorderRadius.circular(16),
            border: ok ? null : Border.all(color: AppColors.purple, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ok ? AppColors.green : AppColors.purple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ok ? '✓' : '✕',
                  style: AppText.body(
                    16,
                    weight: FontWeight.w700,
                    color: ok ? const Color(0xFF123B19) : AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.title,
                      style: AppText.body(15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      check.detail,
                      style: AppText.mono(12, color: const Color(0xFF5A5859)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                check.result,
                style: AppText.body(
                  13,
                  weight: FontWeight.w700,
                  color: ok ? const Color(0xFF2E7D3A) : AppColors.purple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
