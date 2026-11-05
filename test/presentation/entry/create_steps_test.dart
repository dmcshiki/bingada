import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/features/room/presentation/create/create_room_controller.dart';
import 'package:tokingo/features/room/presentation/create/create_room_page.dart';

import 'fakes.dart';

void main() {
  setUp(registerFakes);

  for (final size in const [Size(1488, 935), Size(390, 844)]) {
    for (final step in [1, 2, 3]) {
      testWidgets('create step $step renders at $size', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final c = CreateRoomController()..goTo(step);
        await t.pumpWidget(wrap(CreateRoomPage(controller: c), size: size));
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));
        expect(find.textContaining('Voltar'), findsWidgets);
      });
    }
  }
}
