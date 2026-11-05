import 'package:firebase_auth/firebase_auth.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';

AppUser? appUserFromFirebase(User? u) => u == null
    ? null
    : AppUser(
        uid: UserId(u.uid),
        email: u.email ?? '',
        displayName: u.displayName ?? (u.email ?? '').split('@').first,
        photoUrl: u.photoURL,
        emailVerified: u.emailVerified,
      );

/// Google sign-in through a popup (web).
final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(appUserFromFirebase);

  @override
  AppUser? get currentUser => appUserFromFirebase(_auth.currentUser);

  @override
  Future<AppUser> signInWithGoogle({String? hostedDomain}) async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({
        'prompt': 'select_account',
        if (hostedDomain != null && hostedDomain.isNotEmpty) 'hd': hostedDomain,
      });
    final cred = await _auth.signInWithPopup(provider);
    final user = appUserFromFirebase(cred.user);
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Sign-in aborted');
    }
    return user;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
