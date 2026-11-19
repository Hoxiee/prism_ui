import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';
import '../reclash_sidebar.dart';

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
  var _prismSelected = 0;
  var _reclashSelected = 0;
  var _prismExpanded = true;
  var _reclashExpanded = true;
  var _overlay = false;
  var _narrow = false;
  var _last = 'none yet';

  void _selectNext() => setState(() {
    _prismSelected = (_prismSelected + 1) % _labels.length;
    _reclashSelected = (_reclashSelected + 1) % _labels.length;
  });

  void _toggleBoth() => setState(() {
    final expanded = !(_prismExpanded && _reclashExpanded);
    _prismExpanded = expanded;
    _reclashExpanded = expanded;
  });

  Widget _frame(String title, int selected, Widget sidebar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(title, style: AppTextStyle.headline.of(context)),
        Panel(
          child: SizedBox(
            height: 430,
            child: Row(
              children: [
                sidebar,
                Expanded(
                  child: Center(
                    child: Text(
                      _labels[selected],
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

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          'Hover the rows to see the hover treatment, click to change the '
          'selection, use the toggle at the top of each pane to expand or '
          'collapse. With overlay mode on the toggle opens the pane over the '
          'content instead of widening it.',
        ),
        Controls(
          children: [
            FilledButton(
              onPressed: _selectNext,
              child: const Text('Select next in both'),
            ),
            TextButton(
              onPressed: _toggleBoth,
              child: const Text('Expand / collapse both'),
            ),
            LabeledSwitch(
              label: 'Overlay toggle',
              value: _overlay,
              onChanged: (value) => setState(() => _overlay = value),
            ),
            LabeledSwitch(
              label: 'Reclash narrow',
              value: _narrow,
              onChanged: (value) => setState(() => _narrow = value),
            ),
            Text('Last Reclash action: $_last'),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            Expanded(
              child: _frame(
                'prism NavigationSidebar',
                _prismSelected,
                NavigationSidebar(
                  destinations: [
                    for (var i = 0; i < _labels.length; i++)
                      SidebarDestination(glyph: _glyphs[i], label: _labels[i]),
                  ],
                  selectedIndex: _prismSelected,
                  expanded: _prismExpanded,
                  onSelected: (index) => setState(() => _prismSelected = index),
                  onToggle: _overlay
                      ? null
                      : () => setState(() => _prismExpanded = !_prismExpanded),
                ),
              ),
            ),
            Expanded(
              child: _frame(
                'ReclashSidebar (port)',
                _reclashSelected,
                ReclashSidebar(
                  destinations: [
                    for (var i = 0; i < _labels.length; i++)
                      ReclashSidebarDestination(
                        glyph: _glyphs[i],
                        label: _labels[i],
                        group: _groups[i],
                        id: _labels[i],
                      ),
                  ],
                  actions: [
                    ReclashSidebarAction(
                      glyph: Glyphs.search,
                      tooltip: 'Search',
                      onPressed: () => setState(() => _last = 'Search'),
                    ),
                    ReclashSidebarAction(
                      glyph: Glyphs.more,
                      tooltip: 'More',
                      onPressed: () => setState(() => _last = 'More'),
                    ),
                  ],
                  selectedIndex: _reclashSelected,
                  expanded: _reclashExpanded,
                  narrow: _narrow,
                  onSelected: (index) =>
                      setState(() => _reclashSelected = index),
                  onToggle: _overlay
                      ? null
                      : () =>
                            setState(() => _reclashExpanded = !_reclashExpanded),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
