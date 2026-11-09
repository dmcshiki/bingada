import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/features/game/domain/services/nickname.dart';

void main() {
  test('accepts short common nicknames', () {
    for (final n in ['Ana', 'João Pedro', 'dani_99', 'M.C-2', '  Zé  ']) {
      expect(Nickname.validate(n), isNull, reason: n);
    }
  });

  test('rejects too short, too long or unusual characters', () {
    for (final n in ['A', 'x' * 21, 'oi<script>', 'emoji 😀', 'a@b']) {
      expect(Nickname.validate(n), isNotNull, reason: n);
    }
  });

  test('normalizes spaces', () {
    expect(Nickname.normalize('  Ana   Lu '), 'Ana Lu');
  });

  test('default comes from the first name, cleaned', () {
    expect(Nickname.fromName('Daniel McCarthy'), 'Daniel');
    expect(Nickname.fromName('Ana🙂 Souza'), 'Ana');
    expect(Nickname.fromName(''), 'Jogador');
    expect(Nickname.fromName('A' * 30).length, Nickname.maxLength);
  });
}
