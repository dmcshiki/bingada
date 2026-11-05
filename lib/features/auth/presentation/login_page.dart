import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/help/presentation/how_to_play.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';

/// Login state: optional room preview + sign-in progress.
class LoginController extends ChangeNotifier {
  LoginController({this.code});

  final RoomCode? code;
  Game? room;
  bool busy = false;

  Future<void> loadRoom() async {
    final c = code;
    if (c == null) return;
    try {
      room = await sl<GameRepository>().findByRoomCode(c);
      notifyListeners();
    } on Object {
      // Preview is optional; ignore.
    }
  }

  /// `hd` hint only for a single-domain policy (§2).
  String? get hostedDomain => switch (room?.access) {
    DomainAccess(:final domains) when domains.length == 1 => domains.single,
    _ => null,
  };

  Future<bool> signIn() async {
    busy = true;
    notifyListeners();
    try {
      await sl<AuthRepository>().signInWithGoogle(hostedDomain: hostedDomain);
      return true;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

/// 01 – Entrar + Como jogar.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.next, this.code});

  final String? next;
  final RoomCode? code;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final _c = LoginController(code: widget.code)..loadRoom();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      final ok = await _c.signIn();
      if (!ok || !mounted) return;
      final next = widget.next;
      context.go(
        next != null && next.isNotEmpty
            ? next
            : widget.code != null
            ? AppRoutes.room(widget.code!)
            : AppRoutes.lobby,
      );
    } on Object catch (e, st) {
      debugPrint('Sign-in failed: $e\n$st');
      if (mounted) {
        showFriendlyError(context, _signInErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final left = ListenableBuilder(
      listenable: _c,
      builder: (context, _) =>
          _SignInPanel(controller: _c, onSignIn: _signIn, narrow: narrow),
    );
    final right = Padding(
      padding: narrow
          ? const EdgeInsets.fromLTRB(16, 32, 16, 32)
          : const EdgeInsets.fromLTRB(64, 56, 64, 56),
      child: const HowToPlayPanel(),
    );
    return Scaffold(
      backgroundColor: AppColors.light,
      body: narrow
          ? SingleChildScrollView(child: Column(children: [left, right]))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 620, child: left),
                Expanded(child: SingleChildScrollView(child: right)),
              ],
            ),
    );
  }
}

class _SignInPanel extends StatelessWidget {
  const _SignInPanel({
    required this.controller,
    required this.onSignIn,
    required this.narrow,
  });

  final LoginController controller;
  final VoidCallback onSignIn;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final room = controller.room;
    final code = controller.code;
    return ClipRect(
      child: ColoredBox(
        color: AppColors.primary,
        child: Stack(
          children: [
            blobAt(
              size: 520,
              color: AppColors.primaryStrong,
              right: -220,
              bottom: -200,
            ),
            Padding(
              padding: EdgeInsets.all(narrow ? 24 : 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wordmark(size: narrow ? 34 : 44, color: AppColors.white),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        style: AppText.body(
                          narrow ? 30 : 40,
                          weight: FontWeight.w300,
                          color: AppColors.white,
                          height: 1.15,
                        ),
                        children: const [
                          TextSpan(text: 'bingo de verdade,\n'),
                          TextSpan(
                            text: 'na tela de todo mundo.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SectionCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (code != null) ...[
                          Text.rich(
                            TextSpan(
                              style: AppText.body(14),
                              children: [
                                const TextSpan(text: 'Entrando na sala '),
                                TextSpan(
                                  text: code.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (room != null)
                                  TextSpan(text: ' · ${room.eventName}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (room != null) ...[
                          _PolicyNote(access: room.access),
                          const SizedBox(height: 16),
                        ],
                        _GoogleButton(
                          busy: controller.busy,
                          onPressed: controller.busy ? null : onSignIn,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Usamos só seu nome, foto e e-mail para criar sua cartela. Projeto open source.',
                          style: AppText.body(12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyNote extends StatelessWidget {
  const _PolicyNote({required this.access});

  final AccessPolicy access;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.w700);
    final spans = switch (access) {
      DomainAccess() || SameAsHostAccess() => [
        const TextSpan(text: 'Esta sala aceita só contas '),
        TextSpan(text: accessShort(access), style: bold),
      ],
      AllowlistAccess() => [
        const TextSpan(text: 'Esta sala aceita só '),
        const TextSpan(text: 'e-mails convidados', style: bold),
      ],
      PublicAccess() => [
        const TextSpan(text: 'Esta sala aceita '),
        const TextSpan(text: 'qualquer conta Google verificada', style: bold),
      ],
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text.rich(TextSpan(style: AppText.body(13), children: spans)),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Entrar com Google',
    excludeSemantics: true,
    child: Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const LoadingDots(dotSize: 10, semanticLabel: 'Entrando')
              else
                // Generic person icon: no third-party logo (R12).
                const Icon(
                  Icons.person_outline,
                  color: AppColors.white,
                  size: 22,
                ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Entrar com Google',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    17,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Maps Firebase Auth error codes to a message that says what to fix.
String _signInErrorMessage(Object e) {
  final text = e.toString();
  final code =
      RegExp(r'auth/([a-z-]+)').firstMatch(text)?.group(1) ??
      RegExp(r'\[firebase_auth/([a-z-]+)\]').firstMatch(text)?.group(1);
  return switch (code) {
    'popup-closed-by-user' || 'cancelled-popup-request' => 'Login cancelado.',
    'popup-blocked' =>
      'O navegador bloqueou o pop-up de login. Libere e tente de novo.',
    'operation-not-allowed' => 'Login com Google não está ativado no Firebase (Authentication › Sign-in method).',
    'configuration-not-found' =>
      'Authentication não foi iniciado no console do Firebase.',
    'unauthorized-domain' => 'Este domínio não está autorizado no Firebase (Authentication › Settings › Authorized domains).',
    'invalid-api-key' || 'api-key-not-valid' =>
      'API key do Firebase inválida. Confira config/firebase.json.',
    'network-request-failed' => 'Sem conexão. Tente de novo.',
    null => 'Não foi possível entrar. Tente de novo.',
    _ => 'Não foi possível entrar ($code). Tente de novo.',
  };
}
