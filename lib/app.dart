import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:tokingo/core/router/app_router.dart';
import 'package:tokingo/core/ui/app_theme.dart';

class TokingoApp extends StatefulWidget {
  const TokingoApp({super.key});

  @override
  State<TokingoApp> createState() => _TokingoAppState();
}

class _TokingoAppState extends State<TokingoApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Tokingo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    routerConfig: _router,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    // Every text can be selected and copied, like a regular website. The
    // Overlay gives SelectionArea a place for its handles and copy menu.
    builder: (context, child) => _Selectable(child: child ?? const SizedBox()),
  );
}

/// Makes all text selectable. SelectionArea needs an Overlay above it for
/// its handles and copy menu; the entry is rebuilt whenever [child] changes.
class _Selectable extends StatefulWidget {
  const _Selectable({required this.child});

  final Widget child;

  @override
  State<_Selectable> createState() => _SelectableState();
}

class _SelectableState extends State<_Selectable> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (_) => SelectionArea(child: widget.child),
  );

  @override
  void didUpdateWidget(_Selectable old) {
    super.didUpdateWidget(old);
    if (old.child != widget.child) _entry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
