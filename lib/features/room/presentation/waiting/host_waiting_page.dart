import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';
import 'package:tokingo/features/room/presentation/waiting/open_tab.dart';
import 'package:tokingo/features/room/presentation/waiting/room_watch_controller.dart';

/// Full public URL of a room (R25).
String roomUrl(RoomCode code) {
  final base = Uri.base;
  final origin = base.isScheme('http') || base.isScheme('https')
      ? base.origin
      : 'https://tokingo.app';
  return '$origin${AppRoutes.room(code)}';
}

/// 07 – Sala de espera do host. The host route wrapper switches to the panel
/// when status becomes running; this page does not navigate after start.
class HostWaitingPage extends StatefulWidget {
  const HostWaitingPage({required this.code, super.key});

  final RoomCode code;

  @override
  State<HostWaitingPage> createState() => _HostWaitingPageState();
}

class _HostWaitingPageState extends State<HostWaitingPage> {
  late final _c = RoomWatchController(widget.code, watchPlayers: true)..load();
  bool _starting = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final g = _c.game;
    if (g == null || _starting) return;
    setState(() => _starting = true);
    try {
      await sl<StartGame>()(g);
    } on Object {
      if (mounted) {
        showFriendlyError(context, 'Não foi possível começar. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: roomUrl(widget.code)));
    if (mounted) showFriendlyError(context, 'Link copiado.');
  }

  void _openStream() {
    final path = AppRoutes.stream(widget.code);
    if (!openInNewTab(path)) context.go(path);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final g = _c.game;
      if (_c.loading) return const LoadingView();
      if (g == null) {
        return _Message(
          text: _c.notFound
              ? 'Não achamos essa sala.'
              : 'Não foi possível carregar a sala.',
        );
      }
      final narrow = isNarrow(context);
      final left = _QrPanel(code: widget.code, onCopy: _copy);
      final right = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CountCard(
            game: g,
            starting: _starting,
            onStart: g.status == GameStatus.lobby && !_starting ? _start : null,
          ),
          const SizedBox(height: 20),
          _PlayersGrid(players: _c.players, total: g.playerCount),
        ],
      );
      return Scaffold(
        backgroundColor: AppColors.light,
        body: SafeArea(
          child: Column(
            children: [
              _HostHeader(eventName: g.eventName, onOpenStream: _openStream),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(narrow ? 16 : 24),
                  child: narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [left, const SizedBox(height: 16), right],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 520, child: left),
                            const SizedBox(width: 24),
                            Expanded(child: right),
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

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.light,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: AppText.body(18, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          AppButton(
            label: 'Voltar ao início',
            onPressed: () => context.go(AppRoutes.lobby),
          ),
        ],
      ),
    ),
  );
}

class _HostHeader extends StatelessWidget {
  const _HostHeader({required this.eventName, required this.onOpenStream});

  final String eventName;
  final VoidCallback onOpenStream;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Container(
      height: 72,
      color: AppColors.graphite,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 28),
      child: Row(
        children: [
          // Wide: the wordmark takes its own width (flex 0), not half the row.
          // Narrow: it may shrink to fit.
          Flexible(
            flex: narrow ? 1 : 0,
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Wordmark(size: 24, color: AppColors.white),
            ),
          ),
          const SizedBox(width: 18),
          if (!narrow)
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AppText.body(
                    16,
                    weight: FontWeight.w300,
                    color: AppColors.white,
                  ),
                  children: [
                    const TextSpan(text: 'sala de '),
                    const TextSpan(
                      text: 'espera',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' · $eventName'),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          Semantics(
            link: true,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onOpenStream,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  child: Text(
                    narrow ? 'Transmissão ↗' : 'Abrir tela de transmissão ↗',
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
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.code, required this.onCopy});

  final RoomCode code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final url = roomUrl(code);
    final shown = url.replaceFirst(RegExp('^https?://'), '');
    return SectionCard(
      color: AppColors.navy,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'entradas abertas até o jogo começar',
            style: AppText.body(15, color: AppColors.white),
          ),
          const SizedBox(height: 20),
          Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: QrImageView(
              data: url,
              padding: EdgeInsets.zero,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              semanticsLabel: 'QR code: $shown',
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.navy,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            label: 'Código da sala ${code.value.split('').join(' ')}',
            excludeSemantics: true,
            child: FittedBox(
              child: Text(
                code.value,
                style: AppText.display(
                  72,
                  color: AppColors.white,
                ).copyWith(letterSpacing: 8.6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            shown,
            style: AppText.body(15, color: AppColors.white),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onCopy,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: AppText.body(14, weight: FontWeight.w700),
              ),
              child: const Text('Copiar link'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.game,
    required this.starting,
    required this.onStart,
  });

  final Game game;
  final bool starting;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final me = sl<AuthRepository>().currentUser;
    final hostPlays = game.settings.hostPlays && me?.uid == game.hostUid;
    final access = switch (game.access) {
      PublicAccess() => 'pública',
      final a => accessShort(a),
    };
    final ring = Semantics(
      label: '${game.playerCount} de ${game.maxPlayers} jogadores',
      excludeSemantics: true,
      child: TokenBox(
        size: 120,
        color: AppColors.primary,
        radiusFactor: .25,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${game.playerCount}',
              style: AppText.display(40, color: AppColors.white),
            ),
            Text(
              'de ${game.maxPlayers}',
              style: AppText.body(
                13,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SplitTitle('jogadores', 'na sala', size: 26),
        const SizedBox(height: 6),
        Text(
          'Acesso: $access${hostPlays ? ' · você também está jogando' : ''}',
          style: AppText.body(14),
        ),
      ],
    );
    final action = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: starting ? 'COMEÇANDO…' : 'COMEÇAR E FECHAR SALA',
          onPressed: onStart,
          height: 64,
          displayFont: true,
          fontSize: 22,
        ),
        const SizedBox(height: 8),
        Text(
          'Depois disso ninguém mais entra.',
          style: AppText.body(
            13,
            weight: FontWeight.w700,
            color: AppColors.purple,
          ),
        ),
      ],
    );
    return SectionCard(
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 760
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ring,
                      const SizedBox(width: 24),
                      Expanded(child: info),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(fit: BoxFit.scaleDown, child: action),
                  ),
                ],
              )
            : Row(
                children: [
                  ring,
                  const SizedBox(width: 24),
                  Expanded(child: info),
                  const SizedBox(width: 24),
                  action,
                ],
              ),
      ),
    );
  }
}

class _PlayersGrid extends StatelessWidget {
  const _PlayersGrid({required this.players, required this.total});

  final List<Player> players;
  final int total;

  static const List<Color> _colors = [
    AppColors.navy,
    AppColors.primary,
    AppColors.primaryStrong,
    AppColors.deepBlue,
    AppColors.purple,
    AppColors.graphite,
  ];

  static String _initials(String name) {
    // Canvas: first two letters of the first name.
    final first = name.trim().split(RegExp(r'\s+')).first;
    if (first.isEmpty) return '?';
    return first
        .substring(0, first.length < 2 ? first.length : 2)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final me = sl<AuthRepository>().currentUser?.uid;
    final sorted = [...players]
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return SectionCard(
      child: LayoutBuilder(
        builder: (context, box) {
          final perRow = (box.maxWidth / 100).floor().clamp(3, 6);
          final maxShown = perRow * 3;
          final overflow = sorted.length > maxShown
              ? sorted.length - (maxShown - 1)
              : 0;
          final shown = overflow > 0
              ? sorted.take(maxShown - 1).toList()
              : sorted;
          final w = (box.maxWidth - 16 * (perRow - 1)) / perRow;
          if (sorted.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ninguém entrou ainda. Compartilhe o QR code ou o link.',
                style: AppText.body(15),
              ),
            );
          }
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final (i, p) in shown.indexed)
                SizedBox(
                  width: w,
                  child: _PlayerTile(
                    initials: _initials(p.displayName),
                    name: p.uid == me
                        ? '${p.displayName.split(' ').first} (você)'
                        : p.displayName.split(' ').first,
                    color: _colors[i % _colors.length],
                  ),
                ),
              if (overflow > 0)
                SizedBox(
                  width: w,
                  child: _PlayerTile(
                    initials: '+$overflow',
                    name: '+$overflow',
                    color: _colors[shown.length % _colors.length],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.initials,
    required this.name,
    required this.color,
  });

  final String initials;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: name,
    excludeSemantics: true,
    child: Column(
      children: [
        TokenBox(
          size: 64,
          color: color,
          radiusFactor: .28,
          child: Text(
            initials,
            style: AppText.display(20, color: AppColors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(13),
        ),
      ],
    ),
  );
}
