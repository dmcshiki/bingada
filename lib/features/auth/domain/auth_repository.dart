import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tokingo/core/types/ids.dart';

part 'auth_repository.freezed.dart';

@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required UserId uid,
    required String email,
    required String displayName,
    String? photoUrl,
    @Default(false) bool emailVerified,
  }) = _AppUser;

  String get domain => email.split('@').last.toLowerCase();

  /// Two-letter initials for avatar tokens.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final first = parts.first.isEmpty ? '?' : parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  /// [hostedDomain] narrows the Google account picker (`hd`).
  Future<AppUser> signInWithGoogle({String? hostedDomain});

  Future<void> signOut();
}
