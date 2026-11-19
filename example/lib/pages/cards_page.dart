import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';
import '../settings.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  var _cardSelected = 1;
  var _rowSelected = 0;
  var _holds = false;
  var _fills = false;
  var _translucent = false;

  static const _rows = [
    ('Overview', 'Traffic and connections', Glyphs.eye),
    ('Search', 'Find a proxy or a rule', Glyphs.search),
    ('Pinned', 'Groups kept on top', Glyphs.pin),
  ];

  Widget _cards() {
    return Row(
      spacing: 12,
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Card(
              key: ValueKey('card-$i'),
              isSelected: i == _cardSelected,
              holdsSelection: _holds,
              fillsSelection: _fills,
              onPressed: () => setState(() => _cardSelected = i),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    GlyphIcon(_rows[i].$3),
                    Text(_rows[i].$1, style: AppTextStyle.headline.of(context)),
                    Text(i == _cardSelected ? 'Selected' : 'Press to select'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _list() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListHeader(title: 'Sections', caption: 'Selected rows'),
        for (final (i, row) in _rows.indexed)
          DecorationListItem(
            key: ValueKey('row-$i'),
            title: Text(row.$1),
            subtitle: Text(row.$2),
            leading: GlyphIcon(row.$3),
            isSelected: i == _rowSelected,
            holdsSelection: _holds,
            fillsSelection: _fills,
            onPressed: () => setState(() => _rowSelected = i),
          ),
        const ListFooter(text: 'Rows are grouped by their position.'),
      ],
    );
  }

  Widget _listRows() {
    return Panel(
      child: Column(
        children: [
          for (final row in _rows)
            ListRow(
              leading: GlyphIcon(row.$3),
              title: Text(row.$1),
              subtitle: Text(row.$2),
              trailing: const Text('Value'),
            ),
        ],
      ),
    );
  }

  Widget _fillScope() {
    final child = Row(
      spacing: 12,
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Card(
              onPressed: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Card ${i + 1}'),
              ),
            ),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: AppShape.all(20),
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primaryContainer,
            context.colorScheme.tertiaryContainer,
          ],
        ),
      ),
      child: CardFillScope(
        transform: _translucent
            ? (context, fill) => fill.withValues(alpha: 0.35)
            : null,
        child: child,
      ),
    );
  }

  Widget _contrast() {
    final settings = SettingsScope.of(context);
    final scheme = context.colorScheme;
    final roles = <(String, Color, Color)>[
      ('primary', scheme.primary, scheme.onPrimary),
      ('container', scheme.primaryContainer, scheme.onPrimaryContainer),
      ('secondary', scheme.secondaryContainer, scheme.onSecondaryContainer),
      ('tertiary', scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ('surface', scheme.surfaceContainerHighest, scheme.onSurface),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SegmentedControl<ColorContrast>(
          segments: [
            for (final level in ColorContrast.values) (level, level.name),
          ],
          value: settings.contrast,
          onChanged: (value) => settings.contrast = value,
        ),
        Row(
          spacing: 8,
          children: [
            for (final (name, fill, on) in roles)
              Expanded(
                child: Container(
                  height: 72,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: fill,
                    shape: AppShape.all(16),
                  ),
                  child: Text(name, style: TextStyle(color: on)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        Controls(
          children: [
            LabeledSwitch(
              key: const ValueKey('holds'),
              label: 'holdsSelection',
              value: _holds,
              onChanged: (value) => setState(() => _holds = value),
            ),
            LabeledSwitch(
              key: const ValueKey('fills'),
              label: 'fillsSelection',
              value: _fills,
              onChanged: (value) => setState(() => _fills = value),
            ),
          ],
        ),
        Section(
          title: 'Card',
          caption:
              'A selected card keeps its fill; holdsSelection takes the '
              'secondary container instead.',
          child: Backdrop(child: _cards()),
        ),
        Section(
          title: 'List items with selection',
          child: Backdrop(child: _list()),
        ),
        Section(
          title: 'ListRow',
          child: Backdrop(child: _listRows()),
        ),
        Section(
          title: 'CardFillScope',
          caption:
              'Lets an app change card fills on the page level, such as to '
              'show a wallpaper through.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              LabeledSwitch(
                label: 'Translucent fills',
                value: _translucent,
                onChanged: (value) => setState(() => _translucent = value),
              ),
              _fillScope(),
            ],
          ),
        ),
        Section(
          title: 'ColorContrast',
          caption: 'The level feeds seededColorScheme for the whole gallery.',
          child: _contrast(),
        ),
        const Section(
          title: 'CardSurface',
          child: Note(
            'not demoable standalone: CardSurface is the render object under '
            'Card and needs its animations, fill and metrics from Card.',
          ),
        ),
      ],
    );
  }
}
