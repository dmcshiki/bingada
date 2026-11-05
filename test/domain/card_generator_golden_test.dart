import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/crypto/hashing.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

import 'fixtures.dart';

const _golden = {
  'alice': '0:10,1:11,2:3,3:7,4:14,0:13,1:2,2:0,3:12,4:11,0:5,1:0,_,3:5,4:10,0:6,1:3,2:11,3:1,4:7,0:4,1:7,2:10,3:14,4:6',
  'bob': '0:11,1:1,2:2,3:14,4:14,0:14,1:11,2:7,3:7,4:3,0:13,1:5,_,3:9,4:1,0:0,1:8,2:12,3:12,4:13,0:7,1:9,2:9,3:6,4:8',
  'carol': '0:6,1:14,2:4,3:13,4:5,0:10,1:6,2:10,3:12,4:2,0:8,1:13,_,3:7,4:12,0:14,1:8,2:13,3:10,4:11,0:13,1:9,2:8,3:14,4:4',
};

void main() {
  group('mulberry32', () {
    test('matches JS reference for seed 42', () {
      final r = Mulberry32(42);
      expect(
        [for (var i = 0; i < 5; i++) r.next()],
        [2581720956, 1925393290, 3661312704, 2876485805, 750819978],
      );
    });
    test('imul32 wraps like Math.imul', () {
      expect(imul32(0xFFFFFFFF, 0xFFFFFFFF), 1);
      expect(imul32(0x10000, 0x10000), 0);
    });
  });

  group('CardGenerator golden', () {
    for (final MapEntry(:key, :value) in _golden.entries) {
      test('card for $key', () {
        expect(cardOf(key).cells.map((e) => e?.value ?? '_').join(','), value);
      });
    }
    test('is deterministic and respects columns', () {
      final a = cardOf('alice');
      expect(a, cardOf('alice'));
      for (final (i, id) in a.cells.indexed) {
        if (id == null) {
          expect(i, template.freeCellIndex);
        } else {
          expect(id.column, i % 5);
        }
      }
      final nonFree = a.cells.whereType<ItemId>().toList();
      expect(nonFree.toSet().length, 24);
    });
    test('seedHex is sha256 of uid|gameId|salt', () {
      expect(
        const CardGenerator().seedHex(
          uid: const UserId('alice'),
          gameId: gameId,
          salt: salt,
        ),
        sha256Hex('alice|game-1|$salt'),
      );
    });
  });
}
