import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

const gameId = GameId('game-1');
const salt = 'c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00';
const drawSeed =
    '1111111111111111111111111111111111111111111111111111111111111111';

const p1 = Prize(
  id: PrizeId('p1'),
  label: 'Caneca',
  pattern: PatternKind.horizontal,
  order: 1,
);
const p2 = Prize(
  id: PrizeId('p2'),
  label: 'Vale-café',
  pattern: PatternKind.vertical,
  order: 2,
);
const p3 = Prize(
  id: PrizeId('p3'),
  label: 'Fone',
  pattern: PatternKind.full,
  order: 3,
);
const u1 = Prize(
  id: PrizeId('u1'),
  label: 'Azarão',
  pattern: PatternKind.underdog,
);

final template = CardTemplate.classic75();

BingoCard cardOf(String uid) => const CardGenerator().generate(
  uid: UserId(uid),
  gameId: gameId,
  salt: salt,
  template: template,
);

Game makeGame({
  List<ItemId> draws = const [],
  List<Winner> winners = const [],
  int currentPrizeIndex = 0,
  PrizePolicy policy = const PrizePolicy(),
  ClaimPenaltyPolicy penalty = const ClaimPenaltyPolicy.none(),
  String? seed,
  String? cardsHash,
}) => Game(
  id: gameId,
  roomCode: const RoomCode('K7QP'),
  hostUid: const UserId('host'),
  eventName: 'Teste',
  access: const AccessPolicy.public(),
  template: template,
  prizes: const [p1, p2, p3],
  endOfGamePrizes: const [u1],
  prizePolicy: policy,
  settings: GameSettings(claimPenalty: penalty),
  salt: salt,
  drawCommit: const DrawSequence().commitOf(drawSeed),
  drawSeed: seed,
  cardsHash: cardsHash,
  draws: draws,
  winners: winners,
  currentPrizeIndex: currentPrizeIndex,
  createdAt: DateTime.utc(2026),
);

Claim makeClaim({
  required int drawIndex,
  String id = 'c1',
  String uid = 'alice',
  PrizeId prizeId = const PrizeId('p1'),
  List<int> marked = const [],
  ClaimVerdict? verdict,
  ClaimStatus status = ClaimStatus.pending,
}) => Claim(
  id: ClaimId(id),
  uid: UserId(uid),
  prizeId: prizeId,
  drawIndex: drawIndex,
  markedCells: marked,
  verdict: verdict,
  status: status,
  createdAt: DateTime.utc(2026),
);

/// Cell ids (non-free) of [card] at [cells].
List<ItemId> idsAt(BingoCard card, Iterable<int> cells) => [
  for (final i in cells) ?card.cells[i],
];
