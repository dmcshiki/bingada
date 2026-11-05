import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tokingo/core/types/ids.dart';

part 'prize.freezed.dart';

/// Winning patterns (§5.1).
enum PatternKind {
  horizontal('Horizontal'),
  vertical('Vertical'),
  diagonal('Diagonal'),
  line('Linha'),
  corners('Quatro cantos'),
  x('X'),
  frame('Moldura'),
  full('Cartela cheia'),
  custom('Customizado'),
  underdog('Azarão');

  PatternKind(this.label);

  final String label;
}

/// One detected completed pattern, e.g. `(horizontal, 1)` = "linha 2".
@freezed
abstract class PatternMatch with _$PatternMatch {
  const factory PatternMatch({
    required PatternKind kind,
    @Default(0) int index,
  }) = _PatternMatch;
}

@freezed
abstract class Prize with _$Prize {
  const factory Prize({
    required PrizeId id,
    required String label,
    required PatternKind pattern,
    @Default(1) int winners,

    /// Sequential order (1-based). `null` for end-of-game prizes (underdog).
    int? order,

    /// Row-major mask for [PatternKind.custom].
    List<bool>? customMask,
    String? customName,
  }) = _Prize;
}

/// Who may win again (R30).
@freezed
abstract class PrizePolicy with _$PrizePolicy {
  const factory PrizePolicy({
    /// `null` = unlimited.
    @Default(1) int? maxPerPlayer,

    /// winner of key → may compete for these prizes.
    @Default(<PrizeId, List<PrizeId>>{}) Map<PrizeId, List<PrizeId>> allow,
  }) = _PrizePolicy;
}
