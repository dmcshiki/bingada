import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tokingo/core/types/ids.dart';

part 'card_template.freezed.dart';

/// Where the items of one column come from.
@freezed
sealed class ColumnSource with _$ColumnSource {
  /// Inclusive numeric range, e.g. 1..15.
  const factory ColumnSource.range({required int from, required int to}) =
      RangeSource;

  /// Free list of texts or emojis.
  const factory ColumnSource.items({required List<String> items}) = ItemsSource;
}

@freezed
abstract class FreeCell with _$FreeCell {
  const factory FreeCell({
    @Default(true) bool enabled,
    @Default('★') String label,
    String? imageUrl,
  }) = _FreeCell;
}

/// A drawable item of the pool (one per entry of each column).
@freezed
abstract class PoolItem with _$PoolItem {
  const factory PoolItem({
    required ItemId id,
    required int column,
    required String label,
  }) = _PoolItem;
}

/// Card template configured by the host (§4). Copied frozen into the game.
@freezed
abstract class CardTemplate with _$CardTemplate {
  const CardTemplate._();

  const factory CardTemplate({
    required String name,
    @Default(5) int rows,
    @Default(5) int cols,
    required List<String> headers,
    required List<String> colors,
    @Default(FreeCell()) FreeCell free,
    required List<ColumnSource> columns,
  }) = _CardTemplate;

  /// The classic 75-ball preset.
  factory CardTemplate.classic75() => const CardTemplate(
    name: 'Clássico 75',
    headers: ['B', 'I', 'N', 'G', 'O'],
    colors: ['#779ccf', '#09b5f0', '#4ec45f', '#c679cc', '#914ec4'],
    columns: [
      ColumnSource.range(from: 1, to: 15),
      ColumnSource.range(from: 16, to: 30),
      ColumnSource.range(from: 31, to: 45),
      ColumnSource.range(from: 46, to: 60),
      ColumnSource.range(from: 61, to: 75),
    ],
  );

  /// Row-major index of the free cell, or null when disabled / even size.
  int? get freeCellIndex {
    if (!free.enabled || rows.isEven || cols.isEven) return null;
    return (rows ~/ 2) * cols + (cols ~/ 2);
  }

  /// Labels of a column in order.
  List<String> labelsOf(int column) => switch (columns[column]) {
    RangeSource(:final from, :final to) => [
      for (var n = from; n <= to; n++) '$n',
    ],
    ItemsSource(:final items) => items,
  };

  /// Whole drawable pool, column by column.
  List<PoolItem> get pool => [
    for (var c = 0; c < columns.length; c++)
      for (final (i, label) in labelsOf(c).indexed)
        PoolItem(id: ItemId.of(c, i), column: c, label: label),
  ];

  PoolItem item(ItemId id) =>
      PoolItem(id: id, column: id.column, label: labelsOf(id.column)[id.index]);
}
