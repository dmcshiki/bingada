import 'package:tokingo/features/game/domain/entities/game.dart';

/// Mirrors the `cards.create` access check of `firestore.rules` (§2).
bool accessAllows(AccessPolicy policy, String email) {
  final e = email.trim().toLowerCase();
  final domain = e.split('@').last;
  return switch (policy) {
    DomainAccess(:final domains) =>
      domains.map((d) => d.toLowerCase()).contains(domain),
    SameAsHostAccess(:final hostDomain) => hostDomain.toLowerCase() == domain,
    AllowlistAccess(:final emails) =>
      emails.map((x) => x.toLowerCase()).contains(e),
    PublicAccess() => true,
  };
}

/// Room code alphabet without ambiguous characters (no I, O, 0, 1).
const String kRoomCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
