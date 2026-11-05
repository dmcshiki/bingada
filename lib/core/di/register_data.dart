import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tokingo/core/config/app_config.dart';
import 'package:tokingo/core/config/firebase_options.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/features/auth/data/demo_auth_repository.dart';
import 'package:tokingo/features/auth/data/firebase_auth_repository.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/data/firebase/firebase_game_repository.dart';
import 'package:tokingo/features/game/data/firebase/rtdb_presence_repository.dart';
import 'package:tokingo/features/game/data/local/key_value_store.dart';
import 'package:tokingo/features/game/data/local/local_game_repository.dart';
import 'package:tokingo/features/game/data/prefs_stores.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';

/// Registers the data layer in [sl].
Future<void> registerData({required bool demo}) async {
  sl
    ..registerLazySingleton<HostSecretStore>(PrefsHostSecretStore.new)
    ..registerLazySingleton<MarksStore>(PrefsMarksStore.new);

  if (demo) {
    final kv = KeyValueStore.platform();
    final auth = DemoAuthRepository(kv);
    sl
      ..registerLazySingleton<KeyValueStore>(() => kv)
      ..registerLazySingleton<AuthRepository>(() => auth)
      ..registerLazySingleton<DemoAuthRepository>(() => auth)
      ..registerLazySingleton<GameRepository>(
        () => LocalGameRepository(kv, currentUid: () => auth.currentUser?.uid),
      )
      ..registerLazySingleton<PresenceRepository>(
        () => const DemoPresenceRepository(),
      );
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kUseEmulators) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);
  }
  sl
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(FirebaseAuth.instance),
    )
    ..registerLazySingleton<GameRepository>(
      () => FirebaseGameRepository(FirebaseFirestore.instance),
    )
    ..registerLazySingleton<PresenceRepository>(
      () => RtdbPresenceRepository(
        FirebaseDatabase.instance,
        FirebaseAuth.instance,
      ),
    );
}
