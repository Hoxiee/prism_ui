import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool held}) {
    return tester.pumpWidget(
      HostApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 64,
            child: Card(
              isSelected: true,
              holdsSelection: held,
              onPressed: () {},
              child: const Text('card'),
            ),
          ),
        ),
      ),
    );
  }

  double pressed(WidgetTester tester) =>
      tester.widget<CardSurface>(find.byType(CardSurface)).pressed.value;

  testWidgets('a held card shows an overlay while hovered', (tester) async {
    await pump(tester, held: true);
    expect(find.byKey(Card.heldOverlayKey), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('card')));
    await tester.pump();
    expect(find.byKey(Card.heldOverlayKey), findsOneWidget);

    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();
    expect(find.byKey(Card.heldOverlayKey), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('a held card is pressed under a mouse press', (tester) async {
    await pump(tester, held: true);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('card')),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(pressed(tester), 1);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pressed(tester), 0);
  });

  testWidgets('an unheld card draws no held overlay', (tester) async {
    await pump(tester, held: false);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('card')));
    await tester.pump();
    expect(find.byKey(Card.heldOverlayKey), findsNothing);
    await mouse.removePointer();
  });
}
