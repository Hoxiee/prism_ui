import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';

const _glyphSegments = [
  GlyphSegment(value: 0, glyph: Glyphs.eye, label: 'Overview'),
  GlyphSegment(value: 1, glyph: Glyphs.search, label: 'Search'),
  GlyphSegment(value: 2, glyph: Glyphs.pin, label: 'Pinned'),
  GlyphSegment(value: 3, glyph: Glyphs.copy, label: 'Copies'),
];

const _illustrations = [
  ('search', Illustration.search),
  ('history', Illustration.history),
  ('error', Illustration.error),
];

class SegmentsPage extends StatefulWidget {
  const SegmentsPage({super.key});

  @override
  State<SegmentsPage> createState() => _SegmentsPageState();
}

class _SegmentsPageState extends State<SegmentsPage>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(vsync: this, value: 0);
  var _plain = 'Day';
  var _generation = 0;
  var _selected = 0;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _selected = index);
    springToSegment(_position, index);
  }

  void _pushGuard() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => const _GuardedPage(),
        transitionsBuilder: (context, animation, secondary, child) =>
            SlideOverPageTransition(
              animation: animation,
              secondaryAnimation: secondary,
              dragged: false,
              uncoveredByGesture: false,
              child: child,
            ),
        transitionDuration: SlideOverPageTransition.duration,
        reverseTransitionDuration: SlideOverPageTransition.reverseDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        Section(
          title: 'SegmentedControl',
          child: SegmentedControl<String>(
            segments: const [('Day', 'Day'), ('Week', 'Week'), ('Month', 'Month')],
            value: _plain,
            onChanged: (value) => setState(() => _plain = value),
          ),
        ),
        Section(
          title: 'GlyphSegment and RollingTitle',
          caption:
              'GlyphSegmentedControl springs one position value with '
              'springToSegment and RollingTitle rolls its labels with it.',
          child: Panel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Center(
                  child: GlyphSegmentedControl<int>(
                    segments: _glyphSegments,
                    value: _selected,
                    position: _position,
                    onChanged: _select,
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: DefaultTextStyle(
                    style: AppTextStyle.title1.of(context),
                    child: RollingTitle(
                      labels: [for (final s in _glyphSegments) s.label],
                      position: _position,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Section(
          title: 'NullStatus',
          caption: 'Every illustration; tap one, or press replay, to run its '
              'entrance.',
          child: Panel(
            child: Column(
              children: [
                TonalButton(
                  label: 'Replay',
                  onPressed: () => setState(() => _generation++),
                ),
                for (final (name, illustration) in _illustrations)
                  SizedBox(
                    height: 340,
                    child: NullStatus(
                      key: ValueKey((name, _generation)),
                      label: name,
                      description: 'Matching results will show up here.',
                      illustration: illustration,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Section(
          title: 'PopGuard',
          caption:
              'The pushed route vetoes leaving while its guard is on, which '
              'also turns off the drag back.',
          child: Controls(
            children: [
              FilledButton(
                onPressed: _pushGuard,
                child: const Text('Push guarded route'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuardedPage extends StatefulWidget {
  const _GuardedPage();

  @override
  State<_GuardedPage> createState() => _GuardedPageState();
}

class _GuardedPageState extends State<_GuardedPage> {
  var _guard = true;
  var _vetoed = 0;

  @override
  Widget build(BuildContext context) {
    return PopGuard(
      onPop: _guard
          ? (_) {
              setState(() => _vetoed++);
              return false;
            }
          : null,
      child: Surface(
        color: context.colorScheme.surfaceContainerHigh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text('Guarded route', style: AppTextStyle.title2.of(context)),
              Text('Vetoed pops: $_vetoed'),
              LabeledSwitch(
                label: 'Guard on',
                value: _guard,
                onChanged: (value) => setState(() => _guard = value),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Try to leave'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
