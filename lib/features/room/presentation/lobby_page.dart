import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/help/presentation/how_to_play.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';

/// Outcome of trying to enter a room.
sealed class EnterResult {
  const EnterResult();
}

final class EnterOk extends EnterResult {
  const EnterOk(this.code);
  final RoomCode code;
}

final class EnterError extends EnterResult {
  const EnterError(this.kind, [this.code]);
  final String kind;
  final RoomCode? code;
}

final class EnterNeedsLogin extends EnterResult {
  const EnterNeedsLogin(this.code);
  final RoomCode code;
}

/// Lobby logic: find room → join → route.
class LobbyController extends ChangeNotifier {
  bool busy = false;

  Future<EnterResult> enter(RoomCode code) async {
    busy = true;
    notifyListeners();
    try {
      final repo = sl<GameRepository>();
      final game = await repo.findByRoomCode(code);
      if (game == null) return EnterError(ErrorKinds.invalidCode, code);
      final user = sl<AuthRepository>().currentUser;
      if (user == null) return EnterNeedsLogin(code);
      if (game.status != GameStatus.lobby) {
        final card = await repo.getCard(game.id, user.uid);
        if (card == null) {
          return EnterError(
            game.status == GameStatus.running
                ? ErrorKinds.started
                : ErrorKinds.ended,
            code,
          );
        }
        return EnterOk(code);
      }
      try {
        await sl<JoinGame>()(game, user);
      } on GameFailure catch (f) {
        final kind = errorKindFor(f.code);
        if (kind != null) return EnterError(kind, code);
        rethrow;
      }
      return EnterOk(code);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

/// 02 – Lobby: entrar com código / criar sala.
class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final _c = LobbyController();
  final _code = ValueNotifier<String>('');

  @override
  void dispose() {
    _c.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final code = RoomCode.parse(_code.value);
    if (!code.isWellFormed) {
      showFriendlyError(context, 'O código tem 4 caracteres, como K7QP.');
      return;
    }
    try {
      final r = await _c.enter(code);
      if (!mounted) return;
      switch (r) {
        case EnterOk(:final code):
          context.go(AppRoutes.room(code));
        case EnterError(:final kind, :final code):
          context.go(AppRoutes.error(kind, code: code));
        case EnterNeedsLogin(:final code):
          context.go(
            '${AppRoutes.login}?code=${code.value}&next=${Uri.encodeComponent(AppRoutes.room(code))}',
          );
      }
    } on Object {
      if (mounted) showFriendlyError(context);
    }
  }

  Future<void> _signOut() async {
    try {
      await sl<AuthRepository>().signOut();
    } on Object {
      // ignore
    }
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final user = sl<AuthRepository>().currentUser;
    final join = ListenableBuilder(
      listenable: Listenable.merge([_c, _code]),
      builder: (context, _) => _JoinCard(
        busy: _c.busy,
        canSubmit: _code.value.length == 4 && !_c.busy,
        onChanged: (v) => _code.value = v,
        onSubmit: _enter,
        narrow: narrow,
      ),
    );
    final create = _CreateCard(
      onCreate: () => context.go(AppRoutes.create),
      narrow: narrow,
    );
    return AppPage(
      blobs: const [
        Positioned(
          left: -200,
          top: -260,
          child: BlobShape(size: 600, color: AppColors.blob),
        ),
      ],
      child: Column(
        children: [
          _LobbyHeader(user: user, onSignOut: _signOut),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: narrow
                    ? const EdgeInsets.fromLTRB(16, 16, 16, 32)
                    : const EdgeInsets.fromLTRB(120, 40, 120, 80),
                child: narrow
                    ? Column(
                        children: [join, const SizedBox(height: 16), create],
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (box.maxHeight - 120).clamp(0, 1e6),
                        ),
                        child: Center(
                          child: Row(
                            children: [
                              Expanded(child: join),
                              const SizedBox(width: 32),
                              Expanded(child: create),
                            ],
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

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({required this.user, required this.onSignOut});

  final AppUser? user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final narrow = isNarrow(context);
    return SizedBox(
      height: 72,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 40),
        child: Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Wordmark(),
                ),
              ),
            ),
            HelpButton(onPressed: () => showHowToPlaySheet(context)),
            if (u != null) ...[
              const SizedBox(width: 16),
              Semantics(
                button: true,
                label: '${u.displayName}, sair',
                excludeSemantics: true,
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onSignOut,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AvatarToken(
                            initials: u.initials,
                            size: 36,
                            photoUrl: u.photoUrl,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            narrow
                                ? 'sair'
                                : '${u.displayName.split(' ').first} · sair',
                            style: AppText.body(14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.busy,
    required this.canSubmit,
    required this.onChanged,
    required this.onSubmit,
    required this.narrow,
  });

  final bool busy;
  final bool canSubmit;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final bool narrow;

  @override
  Widget build(BuildContext context) => SectionCard(
    radius: 32,
    padding: EdgeInsets.all(narrow ? 24 : 44),
    child: SizedBox(
      height: narrow ? null : 432,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SplitTitle('entrar numa', 'sala', size: 36),
          const SizedBox(height: 24),
          Text(
            'Código da sala',
            style: AppText.body(14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          CodeBoxes(onChanged: onChanged, onSubmit: onSubmit),
          const SizedBox(height: 24),
          Text(
            'Ou abra o link / QR code que o host compartilhou.',
            style: AppText.body(14),
          ),
          if (narrow) const SizedBox(height: 24) else const Spacer(),
          AppButton(
            label: busy ? 'Entrando…' : 'Entrar na sala',
            onPressed: canSubmit ? onSubmit : null,
            height: 64,
            fontSize: 18,
            expand: true,
          ),
        ],
      ),
    ),
  );
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({required this.onCreate, required this.narrow});

  final VoidCallback onCreate;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final white = AppText.body(15, color: AppColors.white);
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: ColoredBox(
        color: AppColors.navy,
        child: Stack(
          children: [
            const Positioned(
              right: -80,
              bottom: -100,
              child: BlobShape(size: 280, color: AppColors.deepBlue),
            ),
            Padding(
              padding: EdgeInsets.all(narrow ? 24 : 44),
              child: SizedBox(
                height: narrow ? null : 432,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SplitTitle(
                      'criar uma',
                      'sala',
                      size: 36,
                      color: AppColors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Você vira o host: define quem pode entrar, monta a cartela, escolhe os prêmios e canta as bolas. E ainda pode jogar.',
                      style: AppText.body(
                        16,
                        color: AppColors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final s in const [
                      '1 · Acesso',
                      '2 · Cartela',
                      '3 · Prêmios',
                      '4 · Regras e revisão',
                    ]) ...[Text(s, style: white), const SizedBox(height: 10)],
                    if (narrow) const SizedBox(height: 14) else const Spacer(),
                    AppButton(
                      label: 'Criar sala',
                      onPressed: onCreate,
                      kind: AppButtonKind.light,
                      height: 64,
                      fontSize: 18,
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four single-character boxes: auto-advance, uppercase, paste, backspace.
class CodeBoxes extends StatefulWidget {
  const CodeBoxes({required this.onChanged, super.key, this.onSubmit});

  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  @override
  State<CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<CodeBoxes> {
  final List<TextEditingController> _ctrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _nodes = List.generate(
    4,
    (i) => FocusNode(onKeyEvent: (node, e) => _onKey(i, e)),
  );

  static final _allowed = RegExp('[A-Z0-9]');

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  KeyEventResult _onKey(int i, KeyEvent e) {
    if (e is KeyDownEvent &&
        e.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[i].text.isEmpty &&
        i > 0) {
      _ctrls[i - 1].clear();
      _nodes[i - 1].requestFocus();
      _emit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _emit() => widget.onChanged(_ctrls.map((c) => c.text).join());

  void _onInput(int i, String raw) {
    final chars = raw.toUpperCase().split('').where(_allowed.hasMatch).toList();
    if (chars.isEmpty) {
      _ctrls[i].clear();
      _emit();
      return;
    }
    // Paste or fast typing: spread across the following boxes.
    var k = i;
    for (final ch in chars) {
      if (k > 3) break;
      _ctrls[k].value = TextEditingValue(
        text: ch,
        selection: const TextSelection.collapsed(offset: 1),
      );
      k++;
    }
    _emit();
    if (k <= 3) {
      _nodes[k].requestFocus();
    } else {
      _nodes[3].unfocus();
      if (_ctrls.every((c) => c.text.isNotEmpty)) widget.onSubmit?.call();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = ((c.maxWidth - 36) / 4).clamp(52.0, 76.0);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            SizedBox(
              width: w,
              height: w * 92 / 76,
              child: ListenableBuilder(
                listenable: Listenable.merge([_ctrls[i], _nodes[i]]),
                builder: (context, _) {
                  final active =
                      _ctrls[i].text.isNotEmpty || _nodes[i].hasFocus;
                  final border = OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: active ? AppColors.primary : AppColors.light,
                      width: 3,
                    ),
                  );
                  return Semantics(
                    label: '${i + 1}º caractere',
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      autofocus: i == 0,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      expands: true,
                      maxLines: null,
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.visiblePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: AppText.display(
                        w * 40 / 76,
                        color: AppColors.navy,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border,
                        fillColor: AppColors.white,
                      ),
                      onChanged: (v) => _onInput(i, v),
                      onSubmitted: (_) => widget.onSubmit?.call(),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    },
  );
}
