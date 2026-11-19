import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';

const _sets = <String, List<(String, Glyph)>>{
  'Four': [
    ('Home', Glyphs.eye),
    ('Search', Glyphs.search),
    ('Pinned', Glyphs.pin),
    ('More', Glyphs.more),
  ],
  'Three': [
    ('Home', Glyphs.eye),
    ('Pinned', Glyphs.pin),
    ('Sort', Glyphs.sort),
  ],
  'Five': [
    ('Home', Glyphs.eye),
    ('Search', Glyphs.search),
    ('Pinned', Glyphs.pin),
    ('Copy', Glyphs.copy),
    ('More', Glyphs.more),
  ],
};

class DockPage extends StatefulWidget {
  const DockPage({super.key});

  @override
  State<DockPage> createState() => _DockPageState();
}

class _DockPageState extends State<DockPage> {
  var _set = 'Four';
  var _selected = 0;
  var _labels = NavigationDestinationLabelBehavior.alwaysShow;

  List<(String, Glyph)> get _items => _sets[_set]!;

  int get _index => _selected.clamp(0, _items.length - 1);

  List<NavigationDockDestination> get _dock => [
    for (final (index, (label, glyph)) in _items.indexed)
      NavigationDockDestination(
        glyph: glyph,
        label: label,
        id: label,
        group: index >= 2 ? 1 : 0,
      ),
  ];

  Widget _dockDemo(String title, bool compact) {
    return Section(
      title: title,
      child: Panel(
        child: SizedBox(
          height: 150,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingNavigationBar(
                destinations: _dock,
                selectedIndex: _index,
                onSelected: (index) => setState(() => _selected = index),
                labelBehavior: _labels,
                compact: compact,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        Controls(
          children: [
            for (final name in _sets.keys)
              name == _set
                  ? FilledButton(
                      onPressed: () {},
                      child: Text('Set: $name'),
                    )
                  : TextButton(
                      onPressed: () => setState(() => _set = name),
                      child: Text('Set: $name'),
                    ),
          ],
        ),
        SegmentedControl<NavigationDestinationLabelBehavior>(
          segments: const [
            (NavigationDestinationLabelBehavior.alwaysShow, 'Always show'),
            (NavigationDestinationLabelBehavior.onlyShowSelected, 'Selected'),
            (NavigationDestinationLabelBehavior.alwaysHide, 'Hide'),
          ],
          value: _labels,
          onChanged: (value) => setState(() => _labels = value),
        ),
        const Note(
          'Switching the set adds and removes slots on the dock springs. '
          'Drag across the dock to slide the lens; press and hold to lift it.',
        ),
        _dockDemo('FloatingNavigationBar', false),
        _dockDemo('FloatingNavigationBar compact', true),
        Section(
          title: 'AnimatedNavigationBar',
          caption:
              'The flat bar crossfades and resizes between destination sets, '
              'with a divider where the group changes.',
          child: Panel(
            child: AnimatedNavigationBar(
              destinations: [
                for (final (index, (label, glyph)) in _items.indexed)
                  NavigationBarEntry(
                    id: label,
                    icon: GlyphIcon(glyph),
                    label: label,
                    group: index >= 2 ? 1 : 0,
                  ),
              ],
              selectedIndex: _index,
              onSelected: (index) => setState(() => _selected = index),
            ),
          ),
        ),
      ],
    );
  }
}
