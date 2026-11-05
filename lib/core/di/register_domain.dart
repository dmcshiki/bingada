import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/services.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';

/// Pure services as singletons, use cases as factories (§9).
void registerDomain() {
  sl
    ..registerLazySingleton(() => const CardGenerator())
    ..registerLazySingleton(() => const DrawSequence())
    ..registerLazySingleton(() => const PatternDetector())
    ..registerLazySingleton(() => const PrizePolicyEvaluator())
    ..registerLazySingleton(() => const PenaltyEvaluator())
    ..registerLazySingleton(() => const BingoVerifier())
    ..registerLazySingleton(() => const TieBreaker())
    ..registerLazySingleton(() => const UnderdogCalculator())
    ..registerLazySingleton(() => const AuditService())
    ..registerFactory(() => JoinGame(sl<GameRepository>(), sl<CardGenerator>()))
    ..registerFactory(
      () => CreateGame(
        sl<GameRepository>(),
        sl<HostSecretStore>(),
        sl<DrawSequence>(),
        sl<JoinGame>(),
      ),
    )
    ..registerFactory(() => StartGame(sl<GameRepository>(), sl<DrawSequence>()))
    ..registerFactory(
      () => DrawNext(
        sl<GameRepository>(),
        sl<HostSecretStore>(),
        sl<DrawSequence>(),
      ),
    )
    ..registerFactory(() => CallBingo(sl<GameRepository>()))
    ..registerFactory(
      () => VerifyClaim(
        sl<GameRepository>(),
        sl<BingoVerifier>(),
        sl<CardGenerator>(),
      ),
    )
    ..registerFactory(() => ResolveClaim(sl<GameRepository>()))
    ..registerFactory(
      () => ResolveTie(
        sl<HostSecretStore>(),
        sl<DrawSequence>(),
        sl<TieBreaker>(),
      ),
    )
    ..registerFactory(
      () => EndGame(
        sl<GameRepository>(),
        sl<HostSecretStore>(),
        sl<DrawSequence>(),
        sl<UnderdogCalculator>(),
        sl<TieBreaker>(),
      ),
    )
    ..registerFactory(() => ConfirmPrize(sl<GameRepository>(), sl<EndGame>()))
    ..registerLazySingleton(
      () => AwardUnderdog(
        sl<GameRepository>(),
        sl<HostSecretStore>(),
        sl<DrawSequence>(),
        sl<UnderdogCalculator>(),
        sl<TieBreaker>(),
      ),
    );
}
