import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/host_panel_page.dart';
import 'package:tokingo/features/room/presentation/waiting/host_waiting_page.dart';
import 'package:tokingo/features/room/presentation/waiting/player_waiting_page.dart';

/// `/s/:code` for players (deep link / QR): resolves the game, ensures the
/// player's single card (R2) and routes by status.
class PlayerRoomGate extends StatefulWidget {
  const PlayerRoomGate({required this.code, super.key});

  final RoomCode code;

  @override
  State<PlayerRoomGate> createState() => _PlayerRoomGateState();
}

class _PlayerRoomGateState extends State<PlayerRoomGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  Future<void> _resolve() async {
    final router = GoRouter.of(context);
    final code = widget.code;
    final user = sl<AuthRepository>().currentUser;
    final Game? game;
    try {
      game = await sl<GameRepository>().findByRoomCode(code);
    } on GameFailure catch (f) {
      router.go(AppRoutes.error(_errorKind(f.code), code: code));
      return;
    }
    if (game == null) {
      router.go(AppRoutes.error(ErrorKinds.invalidCode, code: code));
      return;
    }
    if (user != null && user.uid == game.hostUid) {
      router.go(AppRoutes.host(code));
      return;
    }
    if (user == null) return;
    try {
      await sl<JoinGame>()(game, user);
    } on GameFailure catch (f) {
      router.go(AppRoutes.error(_errorKind(f.code), code: code));
      return;
    }
    switch (game.status) {
      case GameStatus.running:
        router.go(AppRoutes.play(code));
      case GameStatus.finished || GameStatus.abandoned:
        router.go(AppRoutes.result(code));
      case GameStatus.lobby:
        if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? PlayerWaitingPage(code: widget.code) : const _Loading();
}

String _errorKind(GameFailureCode c) => switch (c) {
  GameFailureCode.accessDenied => ErrorKinds.accessDenied,
  GameFailureCode.roomFull => ErrorKinds.roomFull,
  GameFailureCode.alreadyStarted => ErrorKinds.started,
  GameFailureCode.finished => ErrorKinds.ended,
  _ => ErrorKinds.invalidCode,
};

/// `/s/:code/host`: waiting room (07) while in lobby, panel (11) while
/// running, result once finished. Non-hosts are sent to the player gate.
class HostRoomGate extends StatefulWidget {
  const HostRoomGate({required this.code, super.key});

  final RoomCode code;

  @override
  State<HostRoomGate> createState() => _HostRoomGateState();
}

class _HostRoomGateState extends State<HostRoomGate> {
  Stream<Game>? _stream;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  Future<void> _resolve() async {
    final router = GoRouter.of(context);
    final game = await sl<GameRepository>().findByRoomCode(widget.code);
    final user = sl<AuthRepository>().currentUser;
    if (game == null) {
      router.go(AppRoutes.error(ErrorKinds.invalidCode, code: widget.code));
      return;
    }
    if (user?.uid != game.hostUid) {
      router.go(AppRoutes.room(widget.code));
      return;
    }
    if (mounted) {
      setState(() => _stream = sl<GameRepository>().watchGame(game.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) return const _Loading();
    return StreamBuilder<Game>(
      stream: stream,
      builder: (context, snap) {
        final game = snap.data;
        if (game == null) return const _Loading();
        return switch (game.status) {
          GameStatus.lobby => HostWaitingPage(code: widget.code),
          GameStatus.running => HostPanelPage(code: widget.code),
          GameStatus.finished ||
          GameStatus.abandoned => _RedirectTo(AppRoutes.result(widget.code)),
        };
      },
    );
  }
}

class _RedirectTo extends StatefulWidget {
  const _RedirectTo(this.path);

  final String path;

  @override
  State<_RedirectTo> createState() => _RedirectToState();
}

class _RedirectToState extends State<_RedirectTo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(widget.path);
    });
  }

  @override
  Widget build(BuildContext context) => const _Loading();
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.light,
    body: Center(child: TokenLoader(label: 'Entrando na sala…')),
  );
}
