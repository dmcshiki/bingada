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
  );
}
