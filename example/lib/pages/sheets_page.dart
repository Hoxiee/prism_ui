import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';

class SheetsPage extends StatelessWidget {
  const SheetsPage({super.key});

  Widget _body(BuildContext context, String title, {List<Widget>? extra}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(title, style: AppTextStyle.title2.of(context)),
          const Text('Drag, scroll or tap outside to dismiss.'),
          ...?extra,
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _page(BuildContext context, int depth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text('Sheet page $depth', style: AppTextStyle.title2.of(context)),
          const Note('Pages push inside the sheet and resize it.'),
          for (var i = 0; i < depth * 2; i++) Text('Row ${i + 1}'),
          FilledButton(
            onPressed: () => showInSheet<void>(
              context,
              builder: (context) => _page(context, depth + 1),
            ),
            child: const Text('Push another page'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return PageBody(
      children: [
        Section(
          title: 'Adaptive sheets',
          caption:
              'showSheet, showSnapSheet and showFormSheet open a snap sheet at '
              '600 logical pixels wide or less and a side sheet or centered '
              'form above it; resize the window across 600 while one is open '
              'and it reopens in the other form.',
          child: Controls(
            children: [
              FilledButton(
                key: const ValueKey('sheet-showSheet'),
                onPressed: () => showSheet<void>(
                  context: context,
                  builder: (context) => _body(context, 'showSheet'),
                ),
                child: const Text('showSheet'),
              ),
              FilledButton(
                key: const ValueKey('sheet-showFormSheet'),
                onPressed: () => showFormSheet<void>(
                  context: context,
                  builder: (context) => _body(context, 'showFormSheet'),
                ),
                child: const Text('showFormSheet'),
              ),
              FilledButton(
                key: const ValueKey('sheet-showSnapSheet'),
                onPressed: () => showSnapSheet<void>(
                  context,
                  builder: (context, controller) => ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    children: [
                      Text(
                        'showSnapSheet',
                        style: AppTextStyle.title2.of(context),
                      ),
                      const Note('Drag between the two detents.'),
                      for (var i = 1; i <= 30; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Scrollable row $i'),
                        ),
                    ],
                  ),
                ),
                child: const Text('showSnapSheet'),
              ),
            ],
          ),
        ),
        Section(
          title: 'Side sheet and page',
          caption:
              'showExtend opens a side sheet, and a full page at 600 or less.',
          child: Controls(
            children: [
              FilledButton(
                key: const ValueKey('sheet-showExtend'),
                onPressed: () => showExtend<void>(
                  context,
                  builder: (context) => _body(context, 'showExtend'),
                ),
                child: const Text('showExtend'),
              ),
              FilledButton(
                key: const ValueKey('sheet-showExtend-forceFull'),
                onPressed: () => showExtend<void>(
                  context,
                  props: const ExtendProps(forceFull: true),
                  builder: (context) => _body(context, 'forceFull page'),
                ),
                child: const Text('showExtend forceFull'),
              ),
            ],
          ),
        ),
        Section(
          title: 'Paged sheet',
          caption:
              'NestedPagedSheet keeps its own navigator; showInSheet pushes '
              'into it.',
          child: Controls(
            children: [
              FilledButton(
                key: const ValueKey('sheet-paged'),
                onPressed: () => showSheet<void>(
                  context: context,
                  props: nestedPagedSheetProps,
                  builder: (context) =>
                      NestedPagedSheet(builder: (context) => _page(context, 1)),
                ),
                child: const Text('Open paged sheet'),
              ),
            ],
          ),
        ),
        Section(
          title: 'Stage sheet',
          caption: 'One step of a process: the badge and main button stay put.',
          child: Controls(
            children: [
              FilledButton(
                key: const ValueKey('sheet-stage'),
                onPressed: () => showSheet<void>(
                  context: context,
                  props: stageSheetProps,
                  builder: (context) => StageSheetLayout(
                    hero: StageSheetHero(
                      badge: StageSheetBadge(
                        color: scheme.primary,
                        value: null,
                        child: GlyphIcon(Glyphs.eye, color: scheme.primary),
                      ),
                      title: 'Preparing',
                    ),
                    body: const [Center(child: Text('This takes a moment.'))],
                    primary: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                    secondary: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                child: const Text('StageSheetLayout'),
              ),
            ],
          ),
        ),
        const Section(
          title: 'Modal scrim',
          child: Note(
            'not demoable standalone: ShellModalScrim paints a route scrim '
            'cut to a ShellScrimScope shell and needs a page route animation '
            'inside an app shell.',
          ),
        ),
      ],
    );
  }
}
