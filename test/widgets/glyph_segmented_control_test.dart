import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

import '../helpers/test_app.dart';

const _segments = [
  GlyphSegment(value: 0, glyph: Glyphs.eye, label: 'One'),
  GlyphSegment(value: 1, glyph: Glyphs.search, label: 'Two'),
  GlyphSegment(value: 2, glyph: Glyphs.pin, label: 'Three'),
];

void main() {
  testWidgets('tapping a segment reports its value and the spring settles', (
    tester,
  ) async {
    final position = AnimationController.unbounded(vsync: tester, value: 0);
    addTearDown(position.dispose);
    final changed = <int>[];
    var value = 0;
    await tester.pumpWidget(
      HostApp(
        home: Center(
          child: StatefulBuilder(
            builder: (context, setState) => GlyphSegmentedControl<int>(
              segments: _segments,
              value: value,
              position: position,
              onChanged: (next) {
                changed.add(next);
                setState(() => value = next);
                springToSegment(position, next);
              },
            ),
          ),
        ),
      ),
    );

    final control = find.byType(GlyphSegmentedControl<int>);
    final box = tester.getRect(control);
    await tester.tapAt(Offset(box.right - 32, box.center.dy));
    await tester.pumpAndSettle();

    expect(changed, [2]);
    expect(position.value, closeTo(2, 0.001));
  });
}
