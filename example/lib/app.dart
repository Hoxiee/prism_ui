import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import 'pages.dart';
import 'settings.dart';

class _GalleryUi implements UiLocalizations {
  const _GalleryUi();

  @override
  String get back => 'Back';
  @override
  String get cancel => 'Cancel';
  @override
  String get clearSearch => 'Clear search';
  @override
  String get close => 'Close';
  @override
  String get copy => 'Copy';
  @override
  String get cut => 'Cut';
  @override
  String get dialog => 'Dialog';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get more => 'More';
  @override
  String get noSearchResults => 'No matching results';
  @override
  String get paste => 'Paste';
  @override
  String get reset => 'Reset';
  @override
  String get select => 'Select';
  @override
  String get search => 'Search';
  @override
  String get selectAll => 'Select all';
  @override
  String get showLess => 'Collapse';
  @override
  String get showMore => 'Expand';
  @override
  String get showPassword => 'Show password';
  @override
  String get sort => 'Sort';
  @override
  String get submit => 'Submit';
}

class _UiDelegate extends LocalizationsDelegate<UiLocalizations> {
  const _UiDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<UiLocalizations> load(Locale locale) =>
      SynchronousFuture(const _GalleryUi());

  @override
  bool shouldReload(_UiDelegate old) => false;
}

const _compactWidth = 600.0;

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key, required this.settings, this.fontFamily});

  final GallerySettings settings;

  /// Null keeps the platform font; the screenshot test passes the one it loads.
  final String? fontFamily;

  ThemeData _theme(Brightness brightness) => ThemeData(
    platform: TargetPlatform.linux,
    fontFamily: fontFamily,
    colorScheme: seededColorScheme(
      seedColor: settings.seed,
      brightness: brightness,
      contrast: settings.contrast,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => PrismApp(
        debugShowCheckedModeBanner: false,
        title: 'prism_ui gallery',
        themeMode: settings.dark ? ThemeMode.dark : ThemeMode.light,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        localizationsDelegates: const [_UiDelegate()],
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          return SettingsScope(
            settings: settings,
            child: ViewScope(
              size: size,
              isMobile: size.width <= _compactWidth,
              child: child!,
            ),
          );
        },
        home: const GalleryShell(),
      ),
    );
  }
}

class GalleryShell extends StatelessWidget {
  const GalleryShell({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final compact = MediaQuery.sizeOf(context).width <= _compactWidth;
    final page = galleryPages[settings.page];
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: page.title),
        Expanded(
          child: KeyedSubtree(
            key: ValueKey(page.id),
            child: page.builder(context),
          ),
        ),
      ],
    );
    return Surface(
      color: context.colorScheme.surface,
      child: compact
          ? Column(
              children: [
                Expanded(child: SafeArea(bottom: false, child: body)),
                NavigationDock(
                  destinations: [
                    for (final page in galleryPages)
                      NavigationDockDestination(
                        glyph: page.glyph,
                        label: page.title,
                        id: page.id,
                      ),
                  ],
                  selectedIndex: settings.page,
                  onSelected: (index) => settings.page = index,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                ),
              ],
            )
          : Row(
              children: [
                NavigationSidebar(
                  destinations: [
                    for (final page in galleryPages)
                      SidebarDestination(glyph: page.glyph, label: page.title),
                  ],
                  selectedIndex: settings.page,
                  expanded: settings.sidebarExpanded,
                  onSelected: (index) => settings.page = index,
                  onToggle: settings.toggleSidebar,
                ),
                Expanded(child: SafeArea(left: false, child: body)),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.pageTitle.of(context),
            ),
          ),
          for (final seed in seedChoices)
            _Swatch(
              color: seed,
              selected: seed == settings.seed,
              onTap: () => settings.seed = seed,
            ),
          const SizedBox(width: 4),
          Text(settings.dark ? 'Dark' : 'Light'),
          Switch(
            value: settings.dark,
            onChanged: (value) => settings.dark = value,
            semanticLabel: 'Dark theme',
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = context.colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 26,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: ShapeDecoration(
            shape: AppShape.full.copyWith(
              side: BorderSide(
                color: selected ? ring : const Color(0x00000000),
                width: 2,
              ),
            ),
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(color: color, shape: AppShape.full),
          ),
        ),
      ),
    );
  }
}
