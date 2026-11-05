import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';

/// RTDB `presence/{gameId}/host` with `onDisconnect` (09d).
final class RtdbPresenceRepository implements PresenceRepository {
  RtdbPresenceRepository(this._db, this._auth);

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  DatabaseReference _ref(GameId id) => _db.ref('presence/${id.value}/host');

  @override
  Future<void> announceHost(GameId id) async {
    final ref = _ref(id);
    await ref.onDisconnect().set({
      'online': false,
      'uid': _auth.currentUser?.uid,
      'lastSeen': ServerValue.timestamp,
    });
    await ref.set({
      'online': true,
      'uid': _auth.currentUser?.uid,
      'lastSeen': ServerValue.timestamp,
    });
  }

  @override
  Stream<bool> watchHostOnline(GameId id) => _ref(id).onValue.map((e) {
    final v = e.snapshot.value;
    return v is Map && v['online'] == true;
  });
}
