import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';

/// Draw seed kept only on the host device (localStorage on web).
final class PrefsHostSecretStore implements HostSecretStore {
  PrefsHostSecretStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  String _key(GameId id) => 'tokingo.seed.${id.value}';

  @override
  Future<void> saveDrawSeed(GameId id, String seedHex) =>
      _prefs.setString(_key(id), seedHex);

  @override
  Future<String?> loadDrawSeed(GameId id) => _prefs.getString(_key(id));
}

/// Local stamps of a player (R13).
final class PrefsMarksStore implements MarksStore {
  PrefsMarksStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  String _key(GameId id, UserId uid) =>
      'tokingo.marks.${id.value}.${uid.value}';

  @override
  Future<Set<int>> load(GameId id, UserId uid) async {
    final raw = await _prefs.getStringList(_key(id, uid)) ?? const [];
    return {for (final s in raw) ?int.tryParse(s)};
  }

  @override
  Future<void> save(GameId id, UserId uid, Set<int> marked) =>
      _prefs.setStringList(_key(id, uid), [
        for (final i in marked.toList()..sort()) '$i',
      ]);
}
