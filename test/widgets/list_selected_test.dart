import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart';

import '../helpers/host_scaffold.dart';
import '../helpers/test_app.dart';

void main() {
  Future<BuildContext> pumpItem(
    WidgetTester tester, {
    required bool selected,
    bool fills = true,
    bool invalid = false,
  }) async {
    await tester.pumpWidget(
      TestApp(
        child: HostScaffold(
          body: DecorationListItem(
            title: const Text('Title', key: Key('title')),
            subtitle: const Text('Subtitle', key: Key('subtitle')),
            isSelected: selected,
            fillsSelection: fills,
            invalid: invalid,
            onPressed: () {},
          ),
        ),
      ),
    );
    return tester.element(find.byKey(const Key('title')));
  }

  testWidgets('a row filled by its selection reads in the on-primary color', (
    tester,
  ) async {
    final context = await pumpItem(tester, selected: true);
    final onPrimary = context.colorScheme.onPrimary;

    expect(DefaultTextStyle.of(context).style.color, onPrimary);
    expect(IconTheme.of(context).color, onPrimary);
  });

  testWidgets('a row that is not filled keeps its own text color', (
    tester,
  ) async {
    final unselected = await pumpItem(tester, selected: false);
    final scheme = unselected.colorScheme;
    expect(DefaultTextStyle.of(unselected).style.color, scheme.onSurface);

    final holding = await pumpItem(tester, selected: true, fills: false);
    expect(DefaultTextStyle.of(holding).style.color, scheme.onSurface);
  });
}
