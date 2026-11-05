import 'package:flutter/material.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';

/// Breakpoint below which columns stack (mobile web).
const double kStackBreakpoint = 900;

bool isNarrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kStackBreakpoint;

/// Human description of an access policy, e.g. "@suaempresa.com.br".
String accessShort(AccessPolicy a) => switch (a) {
  DomainAccess(:final domains) => domains.map((d) => '@$d').join(', '),
  SameAsHostAccess(:final hostDomain) => '@$hostDomain',
  AllowlistAccess() => 'lista de convidados',
  PublicAccess() => 'qualquer conta Google verificada',
};

/// Error route for a [GameFailure] while joining.
String? errorKindFor(GameFailureCode code) => switch (code) {
  GameFailureCode.accessDenied => ErrorKinds.accessDenied,
  GameFailureCode.roomFull => ErrorKinds.roomFull,
  GameFailureCode.alreadyStarted => ErrorKinds.started,
  GameFailureCode.finished => ErrorKinds.ended,
  GameFailureCode.roomNotFound => ErrorKinds.invalidCode,
  _ => null,
};

void showFriendlyError(BuildContext context, [String? text]) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(text ?? 'Algo deu errado. Tente de novo em instantes.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// The "?" square button that opens "Como jogar".
class HelpButton extends StatelessWidget {
  const HelpButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Como jogar',
    child: Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                '?',
                style: AppText.display(18, color: AppColors.navy),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Centered spinner used while loading.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.light,
    body: Center(child: TokenLoader(label: 'Carregando…')),
  );
}

/// Positioned decorative blob helper.
Positioned blobAt({
  required double size,
  required Color color,
  double? left,
  double? top,
  double? right,
  double? bottom,
}) => Positioned(
  left: left,
  top: top,
  right: right,
  bottom: bottom,
  child: BlobShape(size: size, color: color),
);
