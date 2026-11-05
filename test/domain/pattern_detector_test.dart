import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

const _d = PatternDetector();
Prize _p(PatternKind k, {List<bool>? mask, String? name}) => Prize(
  id: const PrizeId('x'),
  label: 'x',
  pattern: k,
  customMask: mask,
  customName: name,
);
List<PatternMatch> _c(Set<int> f, PatternKind k, {List<bool>? mask}) =>
    _d.completed(
      filled: f,
      rows: 5,
      cols: 5,
      prize: _p(k, mask: mask),
    );

void main() {
  final row1 = {5, 6, 7, 8, 9};
  final colG = {3, 8, 13, 18, 23};
  final main = {0, 6, 12, 18, 24};
  final anti = {4, 8, 12, 16, 20};
  final all = {for (var i = 0; i < 25; i++) i};
  final frame = {
    for (final i in all)
      if (i < 5 || i > 19 || i % 5 == 0 || i % 5 == 4) i,
  };

  test(
    'horizontal',
    () => expect(_c(row1, PatternKind.horizontal), [
      const PatternMatch(kind: PatternKind.horizontal, index: 1),
    ]),
  );
  test(
    'vertical',
    () => expect(_c(colG, PatternKind.vertical), [
      const PatternMatch(kind: PatternKind.vertical, index: 3),
    ]),
  );
  test('diagonal both', () {
    expect(_c(main, PatternKind.diagonal), [
      const PatternMatch(kind: PatternKind.diagonal),
    ]);
    expect(_c(anti, PatternKind.diagonal), [
      const PatternMatch(kind: PatternKind.diagonal, index: 1),
    ]);
  });
  test('diagonal needs square grid', () {
    expect(
      _d.completed(
        filled: {0, 5, 10},
        rows: 3,
        cols: 5,
        prize: _p(PatternKind.diagonal),
      ),
      isEmpty,
    );
  });
  test('line keeps concrete kinds', () {
    expect(
      _c({...row1, ...main}, PatternKind.line).map((m) => m.kind).toSet(),
      {PatternKind.horizontal, PatternKind.diagonal},
    );
  });
  test('corners', () {
    expect(_c({0, 4, 20, 24}, PatternKind.corners), hasLength(1));
    expect(_c({0, 4, 20}, PatternKind.corners), isEmpty);
  });
  test('x', () {
    expect(_c({...main, ...anti}, PatternKind.x), hasLength(1));
    expect(_c(main, PatternKind.x), isEmpty);
  });
  test('frame', () {
    expect(_c(frame, PatternKind.frame), hasLength(1));
    expect(_c(frame.difference({2}), PatternKind.frame), isEmpty);
  });
  test('full', () {
    expect(_c(all, PatternKind.full), hasLength(1));
    expect(_c(all.difference({12}), PatternKind.full), isEmpty);
  });
  test('custom', () {
    final mask = [for (var i = 0; i < 25; i++) i == 12 || i == 0];
    expect(_c({0, 12}, PatternKind.custom, mask: mask), hasLength(1));
    expect(_c({0}, PatternKind.custom, mask: mask), isEmpty);
    expect(_c(all, PatternKind.custom), isEmpty);
  });
  test(
    'underdog never completes',
    () => expect(_c(all, PatternKind.underdog), isEmpty),
  );
  test('describe', () {
    const h = ['B', 'I', 'N', 'G', 'O'];
    expect(
      _d.describe(
        const PatternMatch(kind: PatternKind.horizontal, index: 1),
        headers: h,
      ),
      'Horizontal · linha 2',
    );
    expect(
      _d.describe(
        const PatternMatch(kind: PatternKind.vertical, index: 3),
        headers: h,
      ),
      'Vertical · coluna G',
    );
    expect(
      _d.describe(const PatternMatch(kind: PatternKind.diagonal), headers: h),
      'Diagonal ↘',
    );
    expect(
      _d.describe(
        const PatternMatch(kind: PatternKind.diagonal, index: 1),
        headers: h,
      ),
      'Diagonal ↙',
    );
    expect(
      _d.describe(const PatternMatch(kind: PatternKind.corners), headers: h),
      'Quatro cantos',
    );
    expect(
      _d.describe(const PatternMatch(kind: PatternKind.full), headers: h),
      'Cartela cheia',
    );
    expect(
      _d.describe(const PatternMatch(kind: PatternKind.custom), headers: h),
      'Customizado',
    );
    expect(
      _d.describe(
        const PatternMatch(kind: PatternKind.custom),
        headers: h,
        prize: _p(PatternKind.custom, name: 'Cruz'),
      ),
      'Cruz',
    );
  });
}
