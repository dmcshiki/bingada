/// Manual (codegen-free) mapping between domain entities and storage maps
/// following the Firestore layout of spec §7.
library;

import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';

typedef Json = Map<String, Object?>;

/// How dates are stored. Firestore uses `Timestamp`, local storage uses
/// epoch milliseconds.
abstract interface class DateCodec {
  Object encode(DateTime value);

  DateTime decode(Object value);
}

/// Epoch-millisecond codec (JSON friendly). Also accepts ISO strings.
final class MillisDateCodec implements DateCodec {
  const MillisDateCodec();

  @override
  Object encode(DateTime value) => value.toUtc().millisecondsSinceEpoch;

  @override
  DateTime decode(Object value) => switch (value) {
    final int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
    final String iso => DateTime.parse(iso).toUtc(),
    final DateTime d => d.toUtc(),
    _ => throw FormatException('Unsupported date value: $value'),
  };
}

/// Free cell marker inside `cards/{uid}.items`.
const String kFreeCellToken = '_';

final class GameMapper {
  const GameMapper([this.dates = const MillisDateCodec()]);

  final DateCodec dates;

  // ---------------------------------------------------------------- helpers

  DateTime? _date(Object? v) => v == null ? null : dates.decode(v);

  static List<T> _list<T>(Object? v, T Function(Object? e) f) =>
      v is List ? [for (final e in v) f(e)] : <T>[];

  static Json _map(Object? v) => v is Map
      ? v.map((k, e) => MapEntry(k.toString(), e))
      : <String, Object?>{};

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  // ----------------------------------------------------------------- access

  Json accessToMap(AccessPolicy a) => switch (a) {
    DomainAccess(:final domains) => {
      'mode': 'domain',
      'domains': [for (final d in domains) d.toLowerCase()],
      'emails': <String>[],
      'hostDomain': null,
    },
    SameAsHostAccess(:final hostDomain) => {
      'mode': 'sameAsHost',
      'domains': <String>[],
      'emails': <String>[],
      'hostDomain': hostDomain.toLowerCase(),
    },
    AllowlistAccess(:final emails) => {
      'mode': 'allowlist',
      'domains': <String>[],
      'emails': [for (final e in emails) e.toLowerCase()],
      'hostDomain': null,
    },
    PublicAccess() => {
      'mode': 'public',
      'domains': <String>[],
      'emails': <String>[],
      'hostDomain': null,
    },
  };

  AccessPolicy accessFromMap(Json m) => switch (m['mode']) {
    'domain' => AccessPolicy.domain(
      domains: _list(m['domains'], (e) => e! as String),
    ),
    'sameAsHost' => AccessPolicy.sameAsHost(
      hostDomain: m['hostDomain'] as String? ?? '',
    ),
    'allowlist' => AccessPolicy.allowlist(
      emails: _list(m['emails'], (e) => e! as String),
    ),
    'public' => const AccessPolicy.public(),
    final other => throw FormatException('Unknown access mode: $other'),
  };

  // --------------------------------------------------------------- template

  Json columnToMap(ColumnSource c) => switch (c) {
    RangeSource(:final from, :final to) => {
      'type': 'range',
      'from': from,
      'to': to,
    },
    ItemsSource(:final items) => {'type': 'items', 'items': items},
  };

  ColumnSource columnFromMap(Json m) => switch (m['type']) {
    'range' => ColumnSource.range(
      from: (m['from']! as num).toInt(),
      to: (m['to']! as num).toInt(),
    ),
    'items' => ColumnSource.items(
      items: _list(m['items'], (e) => e! as String),
    ),
    final other => throw FormatException('Unknown column type: $other'),
  };

  Json templateToMap(CardTemplate t) => {
    'name': t.name,
    'rows': t.rows,
    'cols': t.cols,
    'headers': t.headers,
    'colors': t.colors,
    'free': {
      'enabled': t.free.enabled,
      'label': t.free.label,
      'imageUrl': t.free.imageUrl,
    },
    'columns': [for (final c in t.columns) columnToMap(c)],
  };

  CardTemplate templateFromMap(Json m) {
    final free = _map(m['free']);
    return CardTemplate(
      name: m['name'] as String? ?? '',
      rows: (m['rows'] as num?)?.toInt() ?? 5,
      cols: (m['cols'] as num?)?.toInt() ?? 5,
      headers: _list(m['headers'], (e) => e! as String),
      colors: _list(m['colors'], (e) => e! as String),
      free: FreeCell(
        enabled: free['enabled'] as bool? ?? true,
        label: free['label'] as String? ?? '★',
        imageUrl: free['imageUrl'] as String?,
      ),
      columns: _list(m['columns'], (e) => columnFromMap(_map(e))),
    );
  }

  // ----------------------------------------------------------------- prizes

  Json prizeToMap(Prize p) => {
    'id': p.id.value,
    'label': p.label,
    'pattern': p.pattern.name,
    'winners': p.winners,
    'order': p.order,
    'customMask': p.customMask,
    'customName': p.customName,
  };

  Prize prizeFromMap(Json m) => Prize(
    id: PrizeId(m['id']! as String),
    label: m['label'] as String? ?? '',
    pattern: _enum(PatternKind.values, m['pattern'], PatternKind.full),
    winners: (m['winners'] as num?)?.toInt() ?? 1,
    order: (m['order'] as num?)?.toInt(),
    customMask: m['customMask'] == null
        ? null
        : _list(m['customMask'], (e) => e! as bool),
    customName: m['customName'] as String?,
  );

  Json prizePolicyToMap(PrizePolicy p) => {
    'maxPerPlayer': p.maxPerPlayer,
    'allow': {
      for (final MapEntry(:key, :value) in p.allow.entries)
        key.value: [for (final id in value) id.value],
    },
  };

  PrizePolicy prizePolicyFromMap(Json m) => PrizePolicy(
    maxPerPlayer: m.containsKey('maxPerPlayer')
        ? (m['maxPerPlayer'] as num?)?.toInt()
        : 1,
    allow: {
      for (final MapEntry(:key, :value) in _map(m['allow']).entries)
        PrizeId(key): _list(value, (e) => PrizeId(e! as String)),
    },
  );

  // --------------------------------------------------------------- settings

  Json penaltyToMap(ClaimPenaltyPolicy p) => switch (p) {
    NoPenalty() => {'type': 'none'},
    SkipDraws(:final draws) => {'type': 'skipDraws', 'draws': draws},
  };

  ClaimPenaltyPolicy penaltyFromMap(Object? raw) {
    final m = _map(raw);
    return switch (m['type']) {
      'skipDraws' => ClaimPenaltyPolicy.skipDraws(
        draws: (m['draws'] as num?)?.toInt() ?? 0,
      ),
      _ => const ClaimPenaltyPolicy.none(),
    };
  }

  Json settingsToMap(GameSettings s) => {
    'hostPlays': s.hostPlays,
    'showFailsOnStream': s.showFailsOnStream,
    'tieBreak': s.tieBreak.name,
    'underdogTieBreak': s.underdogTie.name,
    'claimPenalty': penaltyToMap(s.claimPenalty),
    'overLimit': s.overLimit.name,
  };

  GameSettings settingsFromMap(Json m) => GameSettings(
    hostPlays: m['hostPlays'] as bool? ?? true,
    showFailsOnStream: m['showFailsOnStream'] as bool? ?? true,
    tieBreak: _enum(TieBreakRule.values, m['tieBreak'], TieBreakRule.draw),
    underdogTieBreak: m['underdogTieBreak'] == null
        ? null
        : _enum(TieBreakRule.values, m['underdogTieBreak'], TieBreakRule.draw),
    claimPenalty: penaltyFromMap(m['claimPenalty']),
    overLimit: _enum(
      OverLimitRule.values,
      m['overLimit'],
      OverLimitRule.backToGame,
    ),
  );

  Json raffleToMap(Raffle r) => {
    'prizeId': r.prizeId.value,
    'candidates': [for (final u in r.candidates) u.value],
    'kind': r.kind.name,
    'winner': r.winner?.value,
    'releasedBy': r.releasedBy?.value,
  };

  Raffle raffleFromMap(Json m) => Raffle(
    prizeId: PrizeId(m['prizeId']! as String),
    candidates: _list(m['candidates'], (e) => UserId(e! as String)),
    kind: _enum(RaffleKind.values, m['kind'], RaffleKind.released),
    winner: m['winner'] is String ? UserId(m['winner']! as String) : null,
    releasedBy: m['releasedBy'] is String
        ? UserId(m['releasedBy']! as String)
        : null,
  );

  // ---------------------------------------------------------------- winners

  Json winnerToMap(Winner w) => {
    'prizeId': w.prizeId.value,
    'uid': w.uid.value,
    'drawIndex': w.drawIndex,
    'tieBreak': w.tieBreak,
  };

  Winner winnerFromMap(Json m) => Winner(
    prizeId: PrizeId(m['prizeId']! as String),
    uid: UserId(m['uid']! as String),
    drawIndex: (m['drawIndex']! as num).toInt(),
    tieBreak: m['tieBreak'] as bool? ?? false,
  );

  // ------------------------------------------------------------------- game

  /// The `id` is not stored (it is the document id).
  Json gameToMap(Game g) => {
    'roomCode': g.roomCode.value,
    'hostUid': g.hostUid.value,
    'eventName': g.eventName,
    'status': g.status.name,
    'access': accessToMap(g.access),
    'template': templateToMap(g.template),
    'prizes': [for (final p in g.prizes) prizeToMap(p)],
    'endOfGamePrizes': [for (final p in g.endOfGamePrizes) prizeToMap(p)],
    'prizePolicy': prizePolicyToMap(g.prizePolicy),
    'settings': settingsToMap(g.settings),
    'salt': g.salt,
    'drawCommit': g.drawCommit,
    'cardsHash': g.cardsHash,
    'drawSeed': g.drawSeed,
    'playerCount': g.playerCount,
    'maxPlayers': g.maxPlayers,
    'currentPrizeIndex': g.currentPrizeIndex,
    'draws': [for (final d in g.draws) d.value],
    'winners': [for (final w in g.winners) winnerToMap(w)],
    'createdAt': dates.encode(g.createdAt),
    'startedAt': g.startedAt == null ? null : dates.encode(g.startedAt!),
    'endedAt': g.endedAt == null ? null : dates.encode(g.endedAt!),
    'lastActivityAt': g.lastActivityAt == null
        ? null
        : dates.encode(g.lastActivityAt!),
    'raffle': g.raffle == null ? null : raffleToMap(g.raffle!),
  };

  Game gameFromMap(String id, Json m) => Game(
    id: GameId(id),
    roomCode: RoomCode(m['roomCode']! as String),
    hostUid: UserId(m['hostUid']! as String),
    eventName: m['eventName'] as String? ?? '',
    status: _enum(GameStatus.values, m['status'], GameStatus.lobby),
    access: accessFromMap(_map(m['access'])),
    template: templateFromMap(_map(m['template'])),
    prizes: _list(m['prizes'], (e) => prizeFromMap(_map(e))),
    endOfGamePrizes: _list(m['endOfGamePrizes'], (e) => prizeFromMap(_map(e))),
    prizePolicy: m['prizePolicy'] == null
        ? const PrizePolicy()
        : prizePolicyFromMap(_map(m['prizePolicy'])),
    settings: settingsFromMap(_map(m['settings'])),
    salt: m['salt'] as String? ?? '',
    drawCommit: m['drawCommit'] as String? ?? '',
    cardsHash: m['cardsHash'] as String?,
    drawSeed: m['drawSeed'] as String?,
    playerCount: (m['playerCount'] as num?)?.toInt() ?? 0,
    maxPlayers: (m['maxPlayers'] as num?)?.toInt() ?? 60,
    currentPrizeIndex: (m['currentPrizeIndex'] as num?)?.toInt() ?? 0,
    draws: _list(m['draws'], (e) => ItemId(e! as String)),
    winners: _list(m['winners'], (e) => winnerFromMap(_map(e))),
    createdAt: _date(m['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    startedAt: _date(m['startedAt']),
    endedAt: _date(m['endedAt']),
    lastActivityAt: _date(m['lastActivityAt']),
    raffle: m['raffle'] == null ? null : raffleFromMap(_map(m['raffle'])),
  );

  // ----------------------------------------------------------- player/card

  Json playerToMap(Player p) => {
    'uid': p.uid.value,
    'displayName': p.displayName,
    'photoUrl': p.photoUrl,
    'joinedAt': dates.encode(p.joinedAt),
  };

  Player playerFromMap(String uid, Json m) => Player(
    uid: UserId(uid),
    displayName: m['displayName'] as String? ?? '',
    photoUrl: m['photoUrl'] as String?,
    joinedAt: _date(m['joinedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// `cards/{uid}`: items[], algoVersion, displayName, photoUrl, joinedAt.
  Json cardToMap(BingoCard c, {Player? player}) => {
    'items': [for (final i in c.cells) i?.value ?? kFreeCellToken],
    'algoVersion': c.algoVersion,
    if (player != null) ...{
      'displayName': player.displayName,
      'photoUrl': player.photoUrl,
      'joinedAt': dates.encode(player.joinedAt),
    },
  };

  BingoCard cardFromMap(String uid, Json m) => BingoCard(
    owner: UserId(uid),
    cells: _list(
      m['items'],
      (e) => e == null || e == kFreeCellToken ? null : ItemId(e as String),
    ),
    algoVersion: (m['algoVersion'] as num?)?.toInt() ?? 2,
  );

  // ------------------------------------------------------------------ claim

  Json claimToMap(Claim c) => {
    'uid': c.uid.value,
    'prizeId': c.prizeId.value,
    'drawIndex': c.drawIndex,
    'markedCells': c.markedCells,
    'matched': [
      for (final p in c.matched) {'kind': p.kind.name, 'index': p.index},
    ],
    'verdict': c.verdict?.name,
    'status': c.status.name,
    'offerPrizeId': c.offerPrizeId?.value,
    'choice': c.choice?.name,
    'releasePrizeId': c.releasePrizeId?.value,
    'tieOptIn': c.tieOptIn,
    'createdAt': dates.encode(c.createdAt),
  };

  Claim claimFromMap(String id, Json m) => Claim(
    id: ClaimId(id),
    uid: UserId(m['uid']! as String),
    prizeId: PrizeId(m['prizeId']! as String),
    drawIndex: (m['drawIndex']! as num).toInt(),
    markedCells: _list(m['markedCells'], (e) => (e! as num).toInt()),
    status: _enum(ClaimStatus.values, m['status'], ClaimStatus.pending),
    offerPrizeId: m['offerPrizeId'] == null
        ? null
        : PrizeId(m['offerPrizeId']! as String),
    choice: m['choice'] == null
        ? null
        : _enum(ClaimChoice.values, m['choice'], ClaimChoice.keep),
    releasePrizeId: m['releasePrizeId'] is String
        ? PrizeId(m['releasePrizeId']! as String)
        : null,
    verdict: m['verdict'] == null
        ? null
        : _enum(ClaimVerdict.values, m['verdict'], ClaimVerdict.tampered),
    tieOptIn: m['tieOptIn'] as bool? ?? false,
    matched: _list(m['matched'], (e) {
      final p = _map(e);
      return PatternMatch(
        kind: _enum(PatternKind.values, p['kind'], PatternKind.custom),
        index: (p['index'] as num?)?.toInt() ?? 0,
      );
    }),
    createdAt: _date(m['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
