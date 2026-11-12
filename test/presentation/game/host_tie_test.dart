import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/services/services.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';
import 'package:tokingo/features/game/presentation/host/host_panel_controller.dart';
import 'package:tokingo/features/game/presentation/player/player_game_controller.dart';
import 'package:tokingo/features/game/presentation/player/player_game_page.dart';

import 'game_fakes.dart';

class _RecordingRepo extends FakeRepo {
  _RecordingRepo(super.g);

  final chosen = <(ClaimId, ClaimChoice?)>[];

  @override
  Future<void> chooseClaim(
    GameId id,
    ClaimId claimId,
    ClaimChoice? choice, {
    PrizeId? releasePrizeId,
  }) async => chosen.add((claimId, choice));
}

const _code = RoomCode('K7QP');
const _a = UserId('a'), _b = UserId('b'), _c = UserId('c');

Claim _claim(String id, UserId uid, {ClaimStatus s = ClaimStatus.pending}) =>
    Claim(
      id: ClaimId(id),
      uid: uid,
      prizeId: const PrizeId('p2'),
      drawIndex: 23,
      status: s,
      createdAt: DateTime.utc(2026),
    );

HostPanelController _host(FakeRepo repo) {
  final secrets = FakeSecrets();
  const seq = DrawSequence();
  final end = EndGame(
    repo,
    secrets,
    seq,
    const UnderdogCalculator(),
    const TieBreaker(),
  );
  return HostPanelController(
    code: _code,
    repository: repo,
    trackUnderdog: false,
    drawNext: DrawNext(repo, secrets, seq),
    verifyClaim: VerifyClaim(
      repo,
      const BingoVerifier(),
      const CardGenerator(),
    ),
    resolveClaim: ResolveClaim(repo),
    resolveTie: ResolveTie(secrets, seq, const TieBreaker()),
    confirmPrize: ConfirmPrize(repo, end),
    endGame: end,
  );
}

Future<HostPanelController> _started(
  TieBreakRule rule,
  List<Winner> winners,
  List<Claim> claims,
) async {
  final g = runningGame(winners: winners)
      .copyWith(settings: GameSettings(tieBreak: rule));
  final repo = FakeRepo(g)..claims = claims;
  final h = _host(repo);
  await h.start();
  await pumpEventQueue(times: 50);
  return h;
}

Future<void> _pump(WidgetTester t, Widget page) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(wrapGame(page));
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  final tied = [_claim('ca', _a), _claim('cb', _b), _claim('cc', _c)];
  Winner w(String p, UserId u) =>
      Winner(prizeId: PrizeId(p), uid: u, drawIndex: 3);

  group('HostPanelController.tieState contenders', () {
    test('fewestPrizes keeps only those with fewer prizes', () async {
      final h = await _started(TieBreakRule.fewestPrizes, [w('p1', _a)], tied);
      final st = h.tieState(tied);
      expect(st.live.map((c) => c.uid), [_a, _b, _c]);
      expect(st.contenders.map((c) => c.uid), [_b, _c]);
      h.dispose();
    });

    test('draw keeps everyone', () async {
      final h = await _started(TieBreakRule.draw, [w('p1', _a)], tied);
      expect(h.tieState(tied).contenders.map((c) => c.uid), [_a, _b, _c]);
      h.dispose();
    });

    test('fewestPrizes with equal prizes: all contend', () async {
      final h = await _started(TieBreakRule.fewestPrizes, const [], tied);
      expect(h.tieState(tied).contenders.map((c) => c.uid), [_a, _b, _c]);
      h.dispose();
    });
  });

  group('HostPanelController.answerOwnTie', () {
    for (final join in [true, false]) {
      test('join=$join sends ${join ? 'join' : 'skip'}', () async {
        final c = _claim('ch', hostUid, s: ClaimStatus.awaitingChoice);
        final repo = _RecordingRepo(runningGame())..claims = [c];
        final h = _host(repo);
        await h.start();
        await pumpEventQueue(times: 50);
        expect(await h.answerOwnTie(c, join: join), isTrue);
        expect(repo.chosen, [
          (c.id, join ? ClaimChoice.join : ClaimChoice.skip),
        ]);
        h.dispose();
      });
    }
  });

  group('PlayerGameController.bingoBlockedReason', () {
    Future<PlayerGameController> player(List<Claim> claims) async {
      final repo = FakeRepo(runningGame())..claims = claims;
      final p = PlayerGameController(
        code: _code,
        repository: repo,
        auth: FakeAuth(me),
        marks: FakeMarks(),
        callBingo: CallBingo(repo),
      );
      await p.start();
      await pumpEventQueue(times: 50);
      return p;
    }

    test(
      'own pending claim on the current ball blocks a second BINGO',
      () async {
        final p = await player([_claim('c1', me.uid)]);
        expect(p.bingoBlockedReason, 'BINGO ENVIADO · AGUARDE O HOST');
        p.dispose();
      },
    );

    test('older ball or someone else pending does not block', () async {
      final old = _claim('c1', me.uid).copyWith(drawIndex: 22);
      final p = await player([old, _claim('c2', _b)]);
      expect(p.bingoBlockedReason, isNull);
      p.dispose();
    });
  });

  group('PlayerGamePage overlays (embedded vs not)', () {
    for (final embedded in [false, true]) {
      testWidgets('embedded=$embedded: waiting overlay', (t) async {
        final repo = registerGameFakes();
        await _pump(t, _page(embedded: embedded));
        await t.tap(find.text('BINGO!'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));
        expect(repo.claims, hasLength(1), reason: 'BINGO was sent');
        expect(
          find.text('BINGO enviado!'),
          embedded ? findsNothing : findsOneWidget,
        );
      });

      testWidgets('embedded=$embedded: tie opt-in overlay', (t) async {
        final repo = registerGameFakes();
        await _pump(t, _page(embedded: embedded));
        repo.emitClaims([
          _claim(
            'c1',
            me.uid,
            s: ClaimStatus.awaitingChoice,
          ).copyWith(tieOptIn: true),
        ]);
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));
        expect(
          find.bySemanticsLabel('Entrar ou pular o desempate'),
          embedded ? findsNothing : findsOneWidget,
        );
      });
    }
  });
}

/// The host panel hosts the embedded page in a narrow scrollable column.
Widget _page({required bool embedded}) {
  const page = PlayerGamePage(code: _code);
  if (!embedded) return page;
  return const Scaffold(
    body: SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 420,
          child: PlayerGamePage(code: _code, embedded: true),
        ),
      ),
    ),
  );
}
