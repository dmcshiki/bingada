import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';

/// Kind of a game notification; picks the accent color and the glyph.
enum ToastKind {
  /// Someone called BINGO.
  bingo,

  /// A prize was won.
  prize,

  /// A claim was rejected (comeu bola / modalidade errada).
  miss,

  /// Neutral information.
  info,
}

/// One toast: a bold [title] and an optional [body].
@immutable
class ToastData {
  const ToastData({required this.title, this.body, this.kind = ToastKind.info});

  final String title;
  final String? body;
  final ToastKind kind;
}

/// Stack of toasts at the top of the screen, in the Tokingo style: white
/// rounded card, tilted colored token on the left. Each lasts [duration];
/// at most [maxVisible] show at once (oldest drop first).
class ToastLayer extends StatefulWidget {
  const ToastLayer({
    required this.toasts,
    super.key,
    this.duration = const Duration(seconds: 4),
    this.maxVisible = 3,
  });

  final Stream<ToastData> toasts;
  final Duration duration;
  final int maxVisible;

  @override
  State<ToastLayer> createState() => _ToastLayerState();
}

class _Entry {
  _Entry(this.data, this.id);
  final ToastData data;
  final int id;
  Timer? timer;
}

class _ToastLayerState extends State<ToastLayer> {
  final List<_Entry> _items = [];
  StreamSubscription<ToastData>? _sub;
  int _next = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.toasts.listen(_add);
  }

  void _add(ToastData d) {
    if (!mounted) return;
    final e = _Entry(d, _next++);
    e.timer = Timer(widget.duration, () => _remove(e));
    setState(() {
      _items.add(e);
      while (_items.length > widget.maxVisible) {
        _items.removeAt(0).timer?.cancel();
      }
    });
  }

  void _remove(_Entry e) {
    if (!mounted) return;
    e.timer?.cancel();
    setState(() => _items.remove(e));
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    for (final e in _items) {
      e.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width < 480 ? width - 32 : 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in _items)
                  _ToastCard(
                    key: ValueKey(e.id),
                    data: e.data,
                    onClose: () => _remove(e),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.data, required this.onClose, super.key});

  final ToastData data;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (color, glyph) = switch (data.kind) {
      ToastKind.bingo => (AppColors.cyan, '!'),
      ToastKind.prize => (AppColors.green, '★'),
      ToastKind.miss => (AppColors.purple, '✕'),
      ToastKind.info => (AppColors.primary, 'i'),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -16 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Semantics(
          liveRegion: true,
          label: data.body == null ? data.title : '${data.title}. ${data.body}',
          child: ExcludeSemantics(
            child: Material(
              color: AppColors.white,
              elevation: 0,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26424041),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Transform.rotate(
                        angle: -.12,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            glyph,
                            style: AppText.display(
                              20,
                              color: AppColors.onColor(color),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                15,
                                weight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            if (data.body case final b?)
                              Text(
                                b,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(13),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
