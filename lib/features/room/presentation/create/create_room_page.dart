import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/router/routes.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/room/presentation/create/create_room_controller.dart';
import 'package:tokingo/features/room/presentation/create/steps/access_step.dart';
import 'package:tokingo/features/room/presentation/create/steps/card_step.dart';
import 'package:tokingo/features/room/presentation/create/steps/prizes_step.dart';
import 'package:tokingo/features/room/presentation/create/steps/review_step.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';

/// 03–06 – Criar sala wizard.
class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key, this.controller, this.fromGameId});

  /// When set, the wizard is pre-filled with that game's configuration.
  final GameId? fromGameId;

  /// Injectable for tests.
  final CreateRoomController? controller;

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  late final CreateRoomController _c =
      widget.controller ?? CreateRoomController();

  @override
  void initState() {
    super.initState();
    final id = widget.fromGameId;
    if (id != null) unawaited(_prefill(id));
  }

  Future<void> _prefill(GameId id) async {
    try {
      final g = await sl<GameRepository>().getGame(id);
      if (g != null && mounted) _c.prefillFrom(g);
    } on Object {
      // Keep defaults when the previous game cannot be read.
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  void _next() {
    final err = _c.errorForStep(_c.step);
    if (err != null) {
      showFriendlyError(context, err);
      return;
    }
    _c.goTo(_c.step + 1);
  }

  void _back() {
    if (_c.step == 0) {
      context.go(AppRoutes.lobby);
    } else {
      _c.goTo(_c.step - 1);
    }
  }

  void _jump(int s) {
    // Only allow jumping back, or forward through valid steps.
    for (var i = 0; i < s; i++) {
      final err = _c.errorForStep(i);
      if (err != null) {
        _c.goTo(i);
        showFriendlyError(context, err);
        return;
      }
    }
    _c.goTo(s);
  }

  Future<void> _submit() async {
    for (var i = 0; i < 3; i++) {
      final err = _c.errorForStep(i);
      if (err != null) {
        _c.goTo(i);
        showFriendlyError(context, err);
        return;
      }
    }
    try {
      final game = await _c.submit();
      if (mounted) context.go(AppRoutes.host(game.roomCode));
    } on Object catch (e, st) {
      debugPrint('Create room failed: $e\n$st');
      if (mounted) {
        showFriendlyError(context, switch (e) {
          GameFailure(code: GameFailureCode.accessDenied) =>
            'O Firestore recusou a gravação (permission-denied). '
                'Publique as regras: firebase deploy --only firestore:rules,database',
          GameFailure(:final message) when message.isNotEmpty =>
            'Não foi possível criar a sala: $message',
          _ => 'Não foi possível criar a sala. Tente de novo.',
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final narrow = isNarrow(context);
      final body = switch (_c.step) {
        0 => AccessStep(c: _c, onBack: _back, onNext: _next),
        1 => CardStep(c: _c, onBack: _back, onNext: _next),
        2 => PrizesStep(c: _c, onBack: _back, onNext: _next),
        _ => ReviewStep(c: _c, onBack: _back, onSubmit: _submit),
      };
      return AppPage(
        blobs: [
          if (_c.step == 0 || _c.step == 2)
            const Positioned(
              right: -180,
              bottom: -240,
              child: BlobShape(size: 520, color: AppColors.primary),
            ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHeader(step: _c.step, onTap: _jump, narrow: narrow),
            Expanded(
              child: SingleChildScrollView(
                padding: narrow
                    ? const EdgeInsets.fromLTRB(16, 8, 16, 24)
                    : const EdgeInsets.fromLTRB(40, 16, 40, 32),
                child: body,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.onTap,
    required this.narrow,
  });

  final int step;
  final ValueChanged<int> onTap;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final chips = Semantics(
      label: 'Etapas',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, l) in CreateRoomController.stepLabels.indexed)
            _StepChip(
              label: '${i + 1} $l${i < step ? ' ✓' : ''}',
              current: i == step,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 40, vertical: 12),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const Wordmark(), const SizedBox(height: 10), chips],
            )
          : SizedBox(
              height: 48,
              child: Row(
                children: [const Wordmark(), const SizedBox(width: 32), chips],
              ),
            ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.current,
    required this.onTap,
  });

  final String label;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: current,
    child: Material(
      color: current ? AppColors.navy : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppText.body(
                  14,
                  weight: FontWeight.w700,
                  color: current ? AppColors.white : AppColors.graphite,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Footer row with buttons, wraps on narrow screens.
class WizardFooter extends StatelessWidget {
  const WizardFooter({required this.buttons, super.key, this.note});

  final List<Widget> buttons;
  final String? note;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      // Phone width: one button per line, shrunk to fit if a label is long.
      if (c.maxWidth < 520) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (note case final n?) ...[
              Text(n, style: AppText.body(13)),
              const SizedBox(height: 12),
            ],
            for (final (i, b) in buttons.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              FittedBox(fit: BoxFit.scaleDown, child: b),
            ],
          ],
        );
      }
      return _wide();
    },
  );

  Widget _wide() {
    final row = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: buttons,
    );
    final n = note;
    if (n == null) return Align(alignment: Alignment.centerRight, child: row);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Text(n, style: AppText.body(13)),
        row,
      ],
    );
  }
}

/// Two-column layout (main + side) that stacks under the breakpoint.
class WizardColumns extends StatelessWidget {
  const WizardColumns({
    required this.main,
    required this.side,
    required this.sideWidth,
    super.key,
    this.gap = 28,
  });

  final Widget main;
  final Widget side;
  final double sideWidth;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth < kStackBreakpoint - 32) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            main,
            SizedBox(height: gap > 20 ? 20 : gap),
            side,
          ],
        );
      }
      // Both cards fill the viewport below the header (72) and the page
      // padding (16 + 32), like the canvas. IntrinsicHeight can't be used:
      // the steps contain LayoutBuilders, which have no intrinsic size.
      final minHeight = (MediaQuery.sizeOf(context).height - 120)
          .clamp(0, double.infinity)
          .toDouble();
      Widget fill(Widget child) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: child,
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: fill(main)),
          SizedBox(width: gap),
          SizedBox(width: sideWidth, child: fill(side)),
        ],
      );
    },
  );
}
