import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart';
import '../helpers/test_app.dart';

class _Harness extends StatefulWidget {
  const _Harness({required this.controller, this.landing});

  final SplitWorkspaceController controller;
  final Widget? landing;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final pages = <SplitWorkspacePage>[];

  void show(SplitWorkspacePage page) {
    setState(() => pages.add(page));
  }

  void pop(int depth) {
    setState(() => pages.removeRange(depth, pages.length));
  }

  @override
  Widget build(BuildContext context) => SplitWorkspace(
    controller: widget.controller,
    catalog: const Text('catalog'),
    landing: widget.landing,
    pages: pages,
    catalogTitle: 'Catalog',
    landingTitle: 'Landing',
    onPopTo: (depth) async => pop(depth),
    onRemoved: (id) {
      final index = pages.indexWhere((page) => page.id == id);
      if (index >= 0) pop(index);
    },
  );
}

class _Mounted extends StatefulWidget {
  const _Mounted();

  @override
  State<_Mounted> createState() => _MountedState();
}

class _MountedState extends State<_Mounted> {
  @override
  Widget build(BuildContext context) => const Text('page A');
}

Future<_HarnessState> _pump(
  WidgetTester tester, {
  Size size = const Size(1200, 900),
  Widget? landing,
  SplitWorkspaceController? controller,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    HostApp(
      home: _Harness(
        controller: controller ?? SplitWorkspaceController(),
        landing: landing,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_HarnessState>(find.byType(_Harness));
}

Widget _pusher(SplitWorkspaceController controller, Widget page) {
  return Builder(
    builder: (context) => TextButton(
      onPressed: () => controller.pushDetail(context, page),
      child: const Text('open editor'),
    ),
  );
}

void main() {
  testWidgets('a narrow workspace shows the catalog alone', (tester) async {
    final controller = SplitWorkspaceController();
    await _pump(tester, size: const Size(500, 800), controller: controller);

    expect(controller.isSplit, isFalse);
    expect(find.text('catalog'), findsOneWidget);
    expect(find.byKey(SplitWorkspace.dividerKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide workspace splits and divides at its catalog width', (
    tester,
  ) async {
    final controller = SplitWorkspaceController();
    await _pump(tester, controller: controller);

    expect(controller.isSplit, isTrue);
    final divider = find.byKey(SplitWorkspace.dividerKey);
    expect(divider, findsOneWidget);
    expect(tester.getSize(divider).width, 1);
    expect(tester.getCenter(divider).dx, 360.5);
    expect(find.text('catalog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text keeps one pane', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      HostApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1000, 900),
            textScaler: TextScaler.linear(2),
          ),
          child: _Harness(controller: SplitWorkspaceController()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SplitWorkspace.dividerKey), findsNothing);
    expect(find.text('catalog'), findsOneWidget);
  });

  testWidgets('a short workspace keeps one pane', (tester) async {
    await _pump(tester, size: const Size(1200, 400));

    expect(find.byKey(SplitWorkspace.dividerKey), findsNothing);
    expect(find.text('catalog'), findsOneWidget);
  });

  testWidgets('promotion keeps the page that was already mounted', (
    tester,
  ) async {
    final controller = SplitWorkspaceController();
    final state = await _pump(
      tester,
      size: const Size(500, 800),
      controller: controller,
    );
    state.show(
      const SplitWorkspacePage(id: 'a', title: 'A', child: _Mounted()),
    );
    await tester.pumpAndSettle();
    final before = tester.state<_MountedState>(find.byType(_Mounted));
    expect(controller.isSplit, isFalse);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(controller.isSplit, isTrue);
    expect(
      identical(tester.state<_MountedState>(find.byType(_Mounted)), before),
      isTrue,
    );
    expect(find.byKey(SplitWorkspace.dividerKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the landing survives the first page and empties after it', (
    tester,
  ) async {
    final state = await _pump(tester, landing: const Text('landing'));
    expect(find.text('landing'), findsOneWidget);

    state.show(
      const SplitWorkspacePage(id: 'a', title: 'A', child: Text('page A')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('landing'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('landing'), findsNothing);
    expect(find.text('page A'), findsOneWidget);
  });

  testWidgets('detail routes push, dismiss editors and pop', (tester) async {
    final controller = SplitWorkspaceController(detailTitle: (_) => 'Editor');
    final state = await _pump(tester, controller: controller);
    state.show(
      SplitWorkspacePage(
        id: 'a',
        title: 'A',
        child: _pusher(controller, const Text('editor')),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.pageRoutes, hasLength(1));
    expect(controller.pathOf(controller.pageRoutes.first), 'A');

    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsOneWidget);
    expect(controller.topRoute!.settings, isNot(isA<Page<void>>()));
    expect(controller.pathOf(controller.topRoute), 'A › Editor');

    expect(await controller.dismissEditors(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
    expect(controller.pageRoutes, hasLength(1));

    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
    expect(await controller.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a vetoing editor guard keeps the editor mounted', (
    tester,
  ) async {
    final controller = SplitWorkspaceController();
    final state = await _pump(tester, controller: controller);
    var allowed = false;
    var asked = 0;
    state.show(
      SplitWorkspacePage(
        id: 'a',
        title: 'A',
        child: _pusher(
          controller,
          PopGuard(
            onPop: (_) {
              asked++;
              return allowed;
            },
            child: const Text('editor'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();

    expect(await controller.dismissEditors(), isFalse);
    expect(asked, 1);
    expect(find.text('editor'), findsOneWidget);

    allowed = true;
    expect(await controller.dismissEditors(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
  });

  testWidgets('a page popped by the navigator reaches the app', (tester) async {
    final controller = SplitWorkspaceController();
    final state = await _pump(tester, controller: controller);
    state.show(
      const SplitWorkspacePage(id: 'a', title: 'A', child: Text('page A')),
    );
    await tester.pumpAndSettle();
    expect(find.text('page A'), findsOneWidget);

    expect(await controller.maybePop(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('page A'), findsNothing);
    expect(state.pages, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a compact page pops back to the catalog', (tester) async {
    final controller = SplitWorkspaceController();
    final state = await _pump(
      tester,
      size: const Size(500, 800),
      controller: controller,
    );
    state.show(
      const SplitWorkspacePage(id: 'a', title: 'A', child: Text('page A')),
    );
    await tester.pumpAndSettle();
    expect(find.text('catalog'), findsNothing);

    expect(await controller.maybePop(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('page A'), findsNothing);
    expect(find.text('catalog'), findsOneWidget);
    expect(state.pages, isEmpty);
  });
}
