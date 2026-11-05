import 'package:get_it/get_it.dart';

/// Composition root (§9). Registration happens in `configureDependencies`
/// (wired during integration). Presentation reads with `sl<T>()`.
final GetIt sl = GetIt.instance;
