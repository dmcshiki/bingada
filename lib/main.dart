import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tokingo/app.dart';
import 'package:tokingo/core/config/app_config.dart';
import 'package:tokingo/core/di/register_data.dart';
import 'package:tokingo/core/di/register_domain.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Fonts are bundled/served by us in production; avoid runtime fetching
  // surprises in tests and offline events.
  GoogleFonts.config.allowRuntimeFetching = true;
  await registerData(demo: kDemoMode);
  registerDomain();
  runApp(const TokingoApp());
}
