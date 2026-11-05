import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/auth/data/tab_session.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/data/local/key_value_store.dart';

/// DEMO MODE auth: no network. Session and identity are per browser tab
/// (sessionStorage), so each tab is a different player; game data is shared
/// across tabs via localStorage.
/// Use [signInAs] to impersonate another player (e.g. in another tab).
final class DemoAuthRepository implements AuthRepository {
  // The shared store is kept in the signature for DI compatibility; identity
  // is per tab, so it is not used.
  // ignore: avoid_unused_constructor_parameters
  DemoAuthRepository(KeyValueStore kv, {Random? random})
    : _random = random ?? Random() {
    final saved = TabSession.read(_sessionKey);
    if (saved != null) {
      final m = jsonDecode(saved) as Map<String, dynamic>;
      _user = _build(m['name'] as String, m['email'] as String);
    }
  }

  static const _sessionKey = 'tokingo.demo.session';

  final Random _random;
  final StreamController<AppUser?> _ctl = StreamController.broadcast();
  AppUser? _user;

  static const _idKey = 'tokingo.demo.deviceId';

  String get _deviceId {
    final existing = TabSession.read(_idKey);
    if (existing != null) return existing;
    final id = [
      for (var i = 0; i < 8; i++) _random.nextInt(36).toRadixString(36),
    ].join();
    TabSession.write(_idKey, id);
    return id;
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _ctl.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle({String? hostedDomain}) {
    final id = _deviceId;
    final domain = hostedDomain ?? 'demo.local';
    return signInAs(
      'Jogador ${id.substring(0, 4).toUpperCase()}',
      'demo-$id@$domain',
    );
  }

  /// Signs in as an arbitrary (always verified) demo account. The uid is
  /// derived from the e-mail, so the same e-mail is the same account in
  /// every tab.
  Future<AppUser> signInAs(String name, String email) async {
    final user = _build(name, email);
    TabSession.write(
      _sessionKey,
      jsonEncode({'name': user.displayName, 'email': user.email}),
    );
    _user = user;
    _ctl.add(user);
    return user;
  }

  AppUser _build(String name, String email) {
    final normalized = email.trim().toLowerCase();
    final uid =
        'demo_${base64Url.encode(utf8.encode(normalized)).replaceAll('=', '')}';
    return AppUser(
      uid: UserId(uid),
      email: normalized,
      displayName: name.trim().isEmpty
          ? normalized.split('@').first
          : name.trim(),
      emailVerified: true,
    );
  }

  @override
  Future<void> signOut() async {
    TabSession.write(_sessionKey, null);
    _user = null;
    _ctl.add(null);
  }
}
