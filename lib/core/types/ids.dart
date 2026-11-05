/// Strongly-typed identifiers (Dart extension types, zero runtime cost).
library;

extension type const GameId(String value);

extension type const UserId(String value);

/// 4-character room code shown to players (e.g. `K7QP`).
extension type const RoomCode(String value) {
  /// Normalizes user input: trims and upper-cases.
  factory RoomCode.parse(String raw) => RoomCode(raw.trim().toUpperCase());

  bool get isWellFormed => RegExp(r'^[A-Z0-9]{4}$').hasMatch(value);
}

extension type const PrizeId(String value);

/// Identifier of a single drawable item: `"<columnIndex>:<itemIndex>"`.
extension type const ItemId(String value) {
  factory ItemId.of(int column, int index) => ItemId('$column:$index');

  int get column => int.parse(value.split(':').first);

  int get index => int.parse(value.split(':').last);
}

extension type const ClaimId(String value);
