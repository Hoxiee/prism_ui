import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_gallery/app.dart';
import 'package:prism_gallery/pages.dart';
import 'package:prism_gallery/settings.dart';
import 'package:prism_ui/prism_ui.dart';

const _fontFamily = 'GalleryRoboto';
const _fontFiles = [
  '/usr/share/fonts/TTF/Roboto-Regular.ttf',
  '/usr/share/fonts/TTF/Roboto-Bold.ttf',
];
const _viewWidth = 1280.0;
const _viewHeight = 800.0;
const _maxHeight = 8000.0;

Future<void> _loadFonts() async {
  final loader = FontLoader(_fontFamily);
  for (final path in _fontFiles) {
    final file = File(path);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
  }
  await loader.load();
}

Future<void> _settle(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpGallery(
  WidgetTester tester,
  GlobalKey boundary,
  int index, {
  required bool dark,
}) async {
  tester.view.physicalSize = const Size(_viewWidth, _viewHeight);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: GalleryApp(
        settings: GallerySettings(dark: dark, page: index),
        fontFamily: _fontFamily,
      ),
    ),
  );
  await _settle(tester);
}

/// Grows the surface by the page's scroll extent so one image shows it all.
Future<void> _fitPage(WidgetTester tester, String id) async {
  final scrollables = find.descendant(
    of: find.byKey(ValueKey(id)),
    matching: find.byType(Scrollable),
  );
  if (scrollables.evaluate().isEmpty) return;
  final position = tester.state<ScrollableState>(scrollables.first).position;
  final extra = position.maxScrollExtent;
  if (extra <= 0) return;
  tester.view.physicalSize = Size(
    _viewWidth,
    (_viewHeight + extra).clamp(_viewHeight, _maxHeight),
  );
  await _settle(tester, 5);
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  await tester.runAsync(() async {
    final object =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await object.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('screenshots/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Finder _switchIn(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(Switch),
);

typedef _Steps = Future<void> Function(WidgetTester tester);

/// Interaction cases: [steps] run on the page, then the surface is captured.
final _states = <(String page, String state, _Steps steps)>[
  for (final sheet in [
    'showSheet',
    'showFormSheet',
    'showSnapSheet',
    'showExtend',
    'showExtend-forceFull',
    'paged',
    'stage',
  ])
    (
      'sheets',
      sheet,
      (t) async {
        await _tap(t, find.byKey(ValueKey('sheet-$sheet')));
        await _settle(t, 10);
      },
    ),
  (
    'cards',
    'selected',
    (t) async {
      await _tap(t, find.byKey(const ValueKey('card-2')));
      await _tap(t, find.byKey(const ValueKey('row-2')));
      await _settle(t, 5);
    },
  ),
  (
    'cards',
    'holds',
    (t) async {
      await _tap(t, _switchIn('holds'));
      await _settle(t, 5);
    },
  ),
  (
    'cards',
    'fills',
    (t) async {
      await _tap(t, _switchIn('fills'));
      await _tap(t, find.byKey(const ValueKey('card-0')));
      await _settle(t, 5);
    },
  ),
  (
    'motion',
    'spring',
    (t) async {
      await _tap(t, find.byKey(const ValueKey('motion-spring')));
      await t.pump(const Duration(milliseconds: 180));
    },
  ),
  (
    'motion',
    'tabs',
    (t) async {
      await _tap(t, find.byKey(const ValueKey('motion-tab-2')));
      await t.pump(const Duration(milliseconds: 120));
    },
  ),
  (
    'motion',
    'slots',
    (t) async {
      await _tap(t, find.byKey(const ValueKey('motion-slot-add')));
      await t.pump(const Duration(milliseconds: 700));
    },
  ),
  (
    'motion',
    'entries',
    (t) async {
      await _tap(t, find.byKey(const ValueKey('motion-entry-add')));
      await _tap(t, find.byKey(const ValueKey('motion-reveal')));
      await t.pump(const Duration(milliseconds: 700));
    },
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  for (var index = 0; index < galleryPages.length; index++) {
    final id = galleryPages[index].id;
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('screenshot ${id}_$theme', (tester) async {
        final key = GlobalKey();
        await _pumpGallery(tester, key, index, dark: dark);
        await _fitPage(tester, id);
        await _capture(tester, key, '${id}_$theme');
      });

      for (final (page, state, steps) in _states.where((s) => s.$1 == id)) {
        testWidgets('screenshot ${page}_${state}_$theme', (tester) async {
          final key = GlobalKey();
          await _pumpGallery(tester, key, index, dark: dark);
          await steps(tester);
          await _capture(tester, key, '${page}_${state}_$theme');
        });
      }
    }
  }
}
