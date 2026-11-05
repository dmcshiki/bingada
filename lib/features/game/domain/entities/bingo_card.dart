import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tokingo/core/types/ids.dart';

part 'bingo_card.freezed.dart';

/// A player's card. [cells] is row-major; `null` marks the free cell.
@freezed
abstract class BingoCard with _$BingoCard {
  const factory BingoCard({
    required UserId owner,
    required List<ItemId?> cells,
    @Default(2) int algoVersion,
  }) = _BingoCard;
}

/// A player in the room.
@freezed
abstract class Player with _$Player {
  const factory Player({
    required UserId uid,
    required String displayName,
    String? photoUrl,
    required DateTime joinedAt,
  }) = _Player;
}
