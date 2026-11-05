import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/auth/presentation/login_page.dart';
import 'package:tokingo/features/errors/presentation/error_page.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/room/presentation/create/create_room_controller.dart';
import 'package:tokingo/features/room/presentation/create/create_room_page.dart';
import 'package:tokingo/features/room/presentation/lobby_page.dart';
import 'package:tokingo/features/room/presentation/waiting/host_waiting_page.dart';
import 'package:tokingo/features/room/presentation/waiting/player_waiting_page.dart';

import 'fakes.dart';

Future<void> _pump(
  WidgetTester t,
  Widget page, {
  Size size = const Size(1440, 900),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(wrap(page, size: size));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(registerFakes);

  testWidgets('login shows sign-in, room policy and como jogar', (t) async {
    await _pump(t, const LoginPage(code: RoomCode('K7QP')));
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.textContaining('como', findRichText: true), findsWidgets);
    expect(find.text('Passo 1'), findsOneWidget);
    expect(find.text('Entre e pegue sua cartela'), findsOneWidget);
    expect(
      find.textContaining('@suaempresa.com.br', findRichText: true),
      findsOneWidget,
    );
    await t.tap(find.text('Passo 3'));
    await t.pump();
    expect(find.text('Carimbe você mesmo'), findsOneWidget);
  });

  testWidgets('lobby shows join and create cards', (t) async {
    await _pump(t, const LobbyPage());
    expect(
      find.textContaining('entrar numa', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Entrar na sala'), findsOneWidget);
    expect(find.text('Criar sala'), findsOneWidget);
    expect(find.text('Daniel · sair'), findsOneWidget);
  });

  testWidgets('lobby code boxes accept paste across boxes', (t) async {
    await _pump(t, const LobbyPage());
    await t.enterText(find.byType(TextField).first, 'k7q');
    await t.pump();
    expect(find.text('K'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
  });

  testWidgets('host waiting shows QR, code and start button', (t) async {
    await _pump(t, const HostWaitingPage(code: RoomCode('K7QP')));
    expect(find.text('COMEÇAR E FECHAR SALA'), findsOneWidget);
    expect(find.text('K7QP'), findsOneWidget);
    expect(find.text('37'), findsOneWidget);
    expect(find.text('de 60'), findsOneWidget);
    expect(find.text('Daniel (você)'), findsOneWidget);
  });

  testWidgets('player waiting hides end-of-game marker', (t) async {
    await _pump(t, const PlayerWaitingPage(code: RoomCode('K7QP')));
    expect(find.text('Sala fecha quando o jogo começar'), findsOneWidget);
    // Azarão first (it runs during the game), then the pattern prizes.
    expect(find.text('1 Prêmio azarão · Azarão'), findsOneWidget);
    expect(find.text('2 Caneca · Horizontal'), findsOneWidget);
    expect(find.textContaining('Fim de jogo'), findsNothing);
    expect(find.textContaining('encerra o jogo'), findsNothing);
  });

  testWidgets('error page invalid code copy', (t) async {
    await _pump(t, const ErrorPage(kind: 'invalid'));
    expect(find.text('Não achamos essa sala'), findsOneWidget);
    expect(find.text('Digitar de novo'), findsOneWidget);
  });

  testWidgets('create wizard renders step 1 on mobile width', (t) async {
    await _pump(t, const CreateRoomPage(), size: const Size(390, 844));
    expect(
      find.textContaining('quem pode', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Próximo: cartela'), findsOneWidget);
  });

  testWidgets('pages render without overflow at phone width', (t) async {
    for (final page in const <Widget>[
      LoginPage(code: RoomCode('K7QP')),
      LobbyPage(),
      HostWaitingPage(code: RoomCode('K7QP')),
      PlayerWaitingPage(code: RoomCode('K7QP')),
      ErrorPage(kind: 'access', code: RoomCode('K7QP')),
    ]) {
      await _pump(t, page, size: const Size(390, 844));
      expect(t.takeException(), isNull, reason: page.runtimeType.toString());
    }
  });

  test('create controller builds R30 policy from the matrix', () {
    registerFakes();
    final c = CreateRoomController()
      ..domainsText = 'suaempresa.com.br'
      ..setLimit(null);
    expect(c.cell(1, 1), AllowCell.allowed);
    expect(c.cell(1, 0), AllowCell.notApplicable);
    expect(c.cell(2, 0), AllowCell.notApplicable);
    c.toggle(0, 0);
    final input = c.buildInput();
    expect(input.prizes.map((p) => p.id.value), ['p1', 'p2', 'p3']);
    expect(input.prizes.map((p) => p.order), [1, 2, 3]);
    expect(input.endOfGamePrizes.single.id.value, 'u1');
    expect(input.endOfGamePrizes.single.order, isNull);
    expect(input.endOfGamePrizes.single.pattern, PatternKind.underdog);
    expect(input.prizePolicy.maxPerPlayer, isNull);
    expect(input.prizePolicy.allow[const PrizeId('p1')]!.map((e) => e.value), [
      'p3',
      'u1',
    ]);
    expect(input.prizePolicy.allow[const PrizeId('p3')]!.map((e) => e.value), [
      'u1',
    ]);
  });
}
