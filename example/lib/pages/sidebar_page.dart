import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';

const _labels = ['Overview', 'Search', 'Pinned', 'Sorting', 'Copies', 'More'];
const _glyphs = [
  Glyphs.eye,
  Glyphs.search,
  Glyphs.pin,
  Glyphs.sort,
  Glyphs.copy,
  Glyphs.more,
];
const _groups = [0, 0, 1, 1, 2, 2];

class SidebarPage extends StatefulWidget {
  const SidebarPage({super.key});

  @override
  State<SidebarPage> createState() => _SidebarPageState();
}

class _SidebarPageState extends State<SidebarPage> {
  var _selected = 0;
  var _expanded = true;
  var _overlay = false;
  var _narrow = false;
  var _last = 'none yet';

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          'Hover the rows to see the hover ghost, click to change the '
          'selection, use the toggle at the top of the pane to expand or '
          'collapse. With overlay mode on the toggle opens the pane over the '
          'content instead of widening it.',
        ),
        Controls(
          children: [
            FilledButton(
              onPressed: () =>
                  setState(() => _selected = (_selected + 1) % _labels.length),
              child: const Text('Select next'),
            ),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: const Text('Expand / collapse'),
            ),
            LabeledSwitch(
              label: 'Overlay toggle',
              value: _overlay,
              onChanged: (value) => setState(() => _overlay = value),
            ),
            LabeledSwitch(
              label: 'Narrow',
              value: _narrow,
              onChanged: (value) => setState(() => _narrow = value),
            ),
            Text('Last action: $_last'),
          ],
        ),
        Panel(
          child: SizedBox(
            height: 430,
            child: Row(
              children: [
                NavigationSidebar(
                  destinations: [
                    for (var i = 0; i < _labels.length; i++)
                      SidebarDestination(
                        glyph: _glyphs[i],
                        label: _labels[i],
                        group: _groups[i],
                        id: _labels[i],
                      ),
                  ],
                  actions: [
                    SidebarAction(
                      glyph: Glyphs.search,
                      tooltip: 'Search',
                      onPressed: () => setState(() => _last = 'Search'),
                    ),
                    SidebarAction(
                      glyph: Glyphs.more,
                      tooltip: 'More',
                      onPressed: () => setState(() => _last = 'More'),
                    ),
                  ],
                  selectedIndex: _selected,
                  expanded: _expanded,
                  narrow: _narrow,
                  onSelected: (index) => setState(() => _selected = index),
                  onToggle: _overlay
                      ? null
                      : () => setState(() => _expanded = !_expanded),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _labels[_selected],
                      style: AppTextStyle.title2.of(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
