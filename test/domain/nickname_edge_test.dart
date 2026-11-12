import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/features/game/domain/services/nickname.dart';

void main() {
  test('accents are letters', () {
    for (final n in ['Zé', 'Conceição', 'Ñandú', 'Ålvaro Müller']) {
      expect(Nickname.validate(n), isNull, reason: n);
    }
  });

  test('length limits after normalizing', () {
    expect(Nickname.validate('a' * 20), isNull);
    expect(Nickname.validate('a' * 21), isNotNull);
    // Spaces around do not count toward the limit.
    expect(Nickname.validate('   ${'a' * 20}   '), isNull);
    expect(Nickname.validate(' a '), isNotNull);
    // Inner runs collapse to one space.
    expect(Nickname.normalize('ab \t  cd'), 'ab cd');
    expect(Nickname.validate('${'a' * 10}     ${'b' * 9}'), isNull);
  });

  test('fromName fallbacks', () {
    expect(Nickname.fromName('   '), 'Jogador');
    expect(Nickname.fromName('X Souza'), 'Jogador');
    expect(Nickname.fromName('😀😀 Ana'), 'Jogador');
    expect(Nickname.fromName('  João   Silva '), 'João');
    expect(Nickname.fromName('a' * 25), 'a' * 20);
    for (final n in ['Conceição Maria', 'b' * 40, '!!x']) {
      final nick = Nickname.fromName(n);
      expect(Nickname.validate(nick), isNull, reason: '$n -> $nick');
    }
  });
}
