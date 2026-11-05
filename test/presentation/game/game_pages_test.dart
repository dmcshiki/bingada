import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/presentation/host/host_panel_page.dart';
import 'package:tokingo/features/game/presentation/player/player_game_page.dart';
import 'package:tokingo/features/stream/presentation/stream_page.dart';

import 'game_fakes.dart';

const _code = RoomCode('K7QP');

Future<void> _pump(
  WidgetTester t,
  Widget page, {
  Size size = const Size(1440, 900),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(wrapGame(page, size: size));
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Any "N de 75" / "23 bolas" style counter must not exist for players (R23).
final _ballCount = RegExp(
  r'\bde 75\b|\d+\s+bolas?\b|bola \d+',
  caseSensitive: false,
);

bool _anyText(WidgetTester t, RegExp re) => t
    .widgetList<Text>(find.byType(Text))
    .any((w) => re.hasMatch(w.data ?? w.textSpan?.toPlainText() ?? ''));

void main() {
  group('PlayerGamePage', () {
    testWidgets('renders card, BINGO and prizes without any ball count', (
      t,
    ) async {
      registerGameFakes();
      await _pump(t, const PlayerGamePage(code: _code));

      expect(find.text('BINGO!'), findsOneWidget);
      expect(find.text('VALENDO AGORA'), findsOneWidget);
      expect(find.text('Caneca'), findsOneWidget);
      // Pattern prizes are open together; the full card waits.
      expect(find.text('PRÓXIMOS PRÊMIOS'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Bola atual')), findsOneWidget);
      expect(_anyText(t, _ballCount), isFalse, reason: 'R23: no ball count');
      expect(
        find.text('ÚLTIMAS BOLAS'),
        findsNothing,
        reason: 'R23: no history',
      );
      expect(find.text('Você é o host · voltar ao painel'), findsNothing);
    });

    testWidgets('tapping a cell stamps it manually and BINGO looks the same', (
      t,
    ) async {
      registerGameFakes();
      await _pump(t, const PlayerGamePage(code: _code));

      final first = find.bySemanticsLabel(RegExp(r'^B \d+$')).first;
      final label = t.getSemantics(first).label;
      await t.tap(first);
      await t.pump();
      expect(find.bySemanticsLabel('$label, marcado'), findsOneWidget);
      expect(find.text('BINGO!'), findsOneWidget);
    });

    testWidgets('BINGO asks for confirmation and shows the waiting overlay', (
      t,
    ) async {
      final repo = registerGameFakes();
      await _pump(t, const PlayerGamePage(code: _code));

      await t.tap(find.text('BINGO!'));
      await t.pumpAndSettle();
      expect(
        find.text('Tem certeza? Se errar, todo mundo vai saber.'),
        findsOneWidget,
      );
      await t.tap(find.text('Gritar BINGO!'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text('BINGO enviado!'), findsOneWidget);

      repo.emitClaims([
        repo.claims.single.copyWith(
          status: ClaimStatus.rejected,
          verdict: ClaimVerdict.missed,
        ),
      ]);
      await t.pump();
      expect(find.text('COMEU BOLA'), findsOneWidget);
      expect(
        find.textContaining('esse grito não valeu', findRichText: true),
        findsNothing,
      );
      expect(find.textContaining('Esse grito não valeu'), findsOneWidget);
    });

    testWidgets('host sees the back-to-panel link and offline banner', (
      t,
    ) async {
      registerGameFakes(user: me.copyWith(uid: hostUid), hostOnline: false);
      await _pump(t, const PlayerGamePage(code: _code));
      expect(find.text('Você é o host · voltar ao painel'), findsOneWidget);
      expect(
        find.textContaining('Host desconectado.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('works at phone width', (t) async {
      registerGameFakes();
      await _pump(
        t,
        const PlayerGamePage(code: _code),
        size: const Size(390, 844),
      );
      expect(t.takeException(), isNull);
      expect(find.text('BINGO!'), findsOneWidget);
    });
  });

  group('StreamPage', () {
    testWidgets('has no admin controls and no ball count', (t) async {
      registerGameFakes();
      await _pump(
        t,
        const StreamPage(code: _code),
        size: const Size(1600, 900),
      );

      expect(find.text('SORTEAR'), findsNothing);
      expect(find.text('Encerrar partida'), findsNothing);
      expect(find.text('Confirmar vencedor'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      expect(find.text('ÚLTIMAS BOLAS'), findsOneWidget);
      expect(
        find.textContaining('fechada', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('de 75', findRichText: true), findsNothing);
    });

    testWidgets('pending claim shows the checking overlay', (t) async {
      final repo = registerGameFakes();
      await _pump(
        t,
        const StreamPage(code: _code),
        size: const Size(1600, 900),
      );
      repo.emitClaims([
        Claim(
          id: const ClaimId('c1'),
          uid: me.uid,
          prizeId: const PrizeId('p1'),
          drawIndex: 23,
          createdAt: DateTime.utc(2026),
        ),
      ]);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('O HOST ESTÁ CONFERINDO'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
    });
  });

  group('HostPanelPage', () {
    testWidgets('SORTEAR is blocked with a reason while a claim is pending', (
      t,
    ) async {
      final repo = registerGameFakes(user: me.copyWith(uid: hostUid));
      await _pump(t, const HostPanelPage(code: _code));
      expect(find.text('SORTEAR'), findsOneWidget);
      expect(find.textContaining('bola 23 de 75'), findsOneWidget);

      repo.emitClaims([
        Claim(
          id: const ClaimId('c1'),
          uid: me.uid,
          prizeId: const PrizePolicyId('p1'),
          drawIndex: 23,
          createdAt: DateTime.utc(2026),
        ),
      ]);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('antes de sortear'), findsOneWidget);
      expect(find.text('Ana Souza', findRichText: true), findsWidgets);
    });
  });
}

typedef PrizePolicyId = PrizeId;
