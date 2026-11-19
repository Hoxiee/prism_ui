import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_gallery/app.dart';
import 'package:prism_gallery/pages.dart';
import 'package:prism_gallery/settings.dart';

const _fontFamily = 'GalleryRoboto';
const _fontFiles = [
  '/usr/share/fonts/TTF/Roboto-Regular.ttf',
  '/usr/share/fonts/TTF/Roboto-Bold.ttf',
];

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  for (var index = 0; index < galleryPages.length; index++) {
    final id = galleryPages[index].id;
    for (final dark in [false, true]) {
      final name = '${id}_${dark ? 'dark' : 'light'}';
      testWidgets('screenshot $name', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: GalleryApp(
              settings: GallerySettings(dark: dark, page: index),
              fontFamily: _fontFamily,
            ),
          ),
        );
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('screenshots/$name.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(data!.buffer.asUint8List());
        });
      });
    }
  }
}
