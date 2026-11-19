import 'package:prism_ui/icons/icons.dart';

import 'common.dart';
import 'pages/cards_page.dart';
import 'pages/dock_page.dart';
import 'pages/motion_page.dart';
import 'pages/segments_page.dart';
import 'pages/sheets_page.dart';
import 'pages/sidebar_page.dart';
import 'pages/tooltips_page.dart';

final galleryPages = <GalleryPage>[
  GalleryPage('sidebar', 'Sidebar', Glyphs.sort, (_) => const SidebarPage()),
  GalleryPage('dock', 'Navigation dock', Glyphs.pin, (_) => const DockPage()),
  GalleryPage('sheets', 'Sheets', Glyphs.dragHandle, (_) => const SheetsPage()),
  GalleryPage('cards', 'Cards and lists', Glyphs.copy, (_) => const CardsPage()),
  GalleryPage('tooltips', 'Tooltips', Glyphs.eye, (_) => const TooltipsPage()),
  GalleryPage(
    'segments',
    'Segments and empty states',
    Glyphs.search,
    (_) => const SegmentsPage(),
  ),
  GalleryPage('motion', 'Motion', Glyphs.more, (_) => const MotionPage()),
];
