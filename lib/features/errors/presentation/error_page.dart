import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/help/presentation/how_to_play.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';

/// Copy for one error variant (15–15e).
class ErrorCopy {
  const ErrorCopy({
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.fg,
    required this.title,
    required this.text,
    required this.primary,
    required this.secondary,
  });

  final String icon;
  final double iconSize;
  final Color color;
  final Color fg;
  final String title;
  final String text;
  final String primary;
  final String secondary;
}

/// Builds the copy; [access], [email] and [max] fill dynamic parts.
ErrorCopy errorCopyFor(
  String kind, {
  String? access,
  String? email,
  int max = 60,
}) => switch (kind) {
  ErrorKinds.accessDenied => ErrorCopy(
    icon: '@',
    iconSize: 80,
    color: AppColors.purple,
    fg: AppColors.white,
    title: 'Opa, essa sala é fechada',
    text: access == null
        ? 'Essa sala não aceita a conta${email == null ? '' : ' $email'}. Troca de conta?'
        : 'Ela aceita só contas $access${email == null ? '' : ', e você entrou com $email'}. Troca de conta?',
    primary: 'Trocar de conta',
    secondary: 'Voltar ao início',
  ),
  ErrorKinds.roomFull => ErrorCopy(
    icon: '$max',
    iconSize: 64,
    color: AppColors.graphite,
    fg: AppColors.white,
    title: 'Sala cheia: $max/$max',
    text: 'Todas as cartelas já têm dono. Avise o host. Se alguém sair antes do início, a vaga reabre.',
    primary: 'Tentar de novo',
    secondary: 'Voltar ao início',
  ),
  ErrorKinds.started => const ErrorCopy(
    icon: '▶',
    iconSize: 64,
    color: AppColors.primary,
    fg: AppColors.white,
    title: 'O jogo já começou',
    text: 'Novas cartelas não entram depois da primeira bola. Você pode assistir pela tela de transmissão.',
    primary: 'Assistir',
    secondary: 'Voltar ao início',
  ),
  ErrorKinds.ended => const ErrorCopy(
    icon: '✓',
    iconSize: 72,
    color: AppColors.green,
    fg: Color(0xFF123B19),
    title: 'Esse jogo acabou',
    text: 'O último prêmio já saiu. Confira os vencedores e audite a partida.',
    primary: 'Ver resultado',
    secondary: 'Voltar ao início',
  ),
  _ => const ErrorCopy(
    icon: '?',
    iconSize: 80,
    color: AppColors.pink,
    fg: AppColors.inkOnLight,
    title: 'Não achamos essa sala',
    text: 'Confira o código com o host. São 4 caracteres, como K7QP.',
    primary: 'Digitar de novo',
    secondary: 'Como jogar',
  ),
};

/// 15–15e – error screens.
class ErrorPage extends StatefulWidget {
  const ErrorPage({required this.kind, super.key, this.code});

  final String kind;
  final RoomCode? code;

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  Game? _game;

  @override
  void initState() {
    super.initState();
    final c = widget.code;
    if (c != null &&
        (widget.kind == ErrorKinds.accessDenied ||
            widget.kind == ErrorKinds.roomFull)) {
      unawaited(
        sl<GameRepository>().findByRoomCode(c).then((g) {
          if (mounted) setState(() => _game = g);
        }, onError: (Object _) {}),
      );
    }
  }

  Future<void> _primary() async {
    final code = widget.code;
    switch (widget.kind) {
      case ErrorKinds.accessDenied:
        try {
          await sl<AuthRepository>().signOut();
        } on Object {
          // ignore
        }
        if (!mounted) return;
        context.go(
          code == null
              ? AppRoutes.login
              : '${AppRoutes.login}?code=${code.value}&next=${Uri.encodeComponent(AppRoutes.room(code))}',
        );
      case ErrorKinds.roomFull:
        context.go(code == null ? AppRoutes.lobby : AppRoutes.room(code));
      case ErrorKinds.started:
        context.go(code == null ? AppRoutes.lobby : AppRoutes.stream(code));
      case ErrorKinds.ended:
        context.go(code == null ? AppRoutes.lobby : AppRoutes.result(code));
      default:
        context.go(AppRoutes.lobby);
    }
  }

  void _secondary() {
    if (widget.kind == ErrorKinds.invalidCode) {
      unawaited(showHowToPlaySheet(context));
    } else {
      context.go(AppRoutes.lobby);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _game;
    final copy = errorCopyFor(
      widget.kind,
      access: g == null ? null : accessShort(g.access),
      email: sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUser?.email
          : null,
      max: g?.maxPlayers ?? 60,
    );
    final narrow = isNarrow(context);
    return AppPage(
      blobs: const [
        Positioned(
          left: -200,
          bottom: -280,
          child: BlobShape(size: 600, color: AppColors.blob),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 40),
              child: const Row(children: [Wordmark()]),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _ErrorCard(
                    copy: copy,
                    narrow: narrow,
                    onPrimary: _primary,
                    onSecondary: _secondary,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.copy,
    required this.narrow,
    required this.onPrimary,
    required this.onSecondary,
  });

  final ErrorCopy copy;
  final bool narrow;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final token = ExcludeSemantics(
      child: TokenBox(
        size: narrow ? 120 : 180,
        color: copy.color,
        child: Text(
          copy.icon,
          style: AppText.display(
            narrow ? copy.iconSize * .66 : copy.iconSize,
            color: copy.fg,
          ),
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            copy.title,
            style: AppText.display(narrow ? 28 : 34, color: AppColors.navy),
          ),
        ),
        const SizedBox(height: 14),
        Text(copy.text, style: AppText.body(17, height: 1.5)),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppButton(label: copy.primary, onPressed: onPrimary),
            AppButton(
              label: copy.secondary,
              onPressed: onSecondary,
              kind: AppButtonKind.outline,
            ),
          ],
        ),
      ],
    );
    return SectionCard(
      radius: 36,
      padding: EdgeInsets.all(narrow ? 28 : 52),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [token, const SizedBox(height: 28), text],
            )
          : Row(
              children: [
                SizedBox(width: 200, child: Center(child: token)),
                const SizedBox(width: 40),
                Expanded(child: text),
              ],
            ),
    );
  }
}
