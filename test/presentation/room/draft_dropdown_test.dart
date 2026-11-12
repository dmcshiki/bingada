import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/features/room/presentation/create/create_widgets.dart';

void main() {
  testWidgets('narrow dropdown cuts long text and shows it on hover', (
    tester,
  ) async {
    const long = 'Faixa de números bem comprida';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DraftDropdown<int>(
              width: 120,
              semanticsLabel: 'Tipo',
              value: 1,
              items: const [(1, long), (2, 'Lista')],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull); // no overflow
    final tip = tester.widget<Tooltip>(find.byType(Tooltip).first);
    expect(tip.message, long);
  });
}
