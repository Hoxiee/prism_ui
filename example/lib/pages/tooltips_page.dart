import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';

const _paths = [
  'Settings',
  'Settings › Network',
  'Settings › Network › DNS',
  'Settings › Appearance',
];

class TooltipsPage extends StatefulWidget {
  const TooltipsPage({super.key});

  @override
  State<TooltipsPage> createState() => _TooltipsPageState();
}

class _TooltipsPageState extends State<TooltipsPage>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1,
  );
  var _placement = AppTooltipPlacement.auto;
  var _previous = _paths[0];
  var _title = _paths[0];
  var _clicked = 'none';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(String path) {
    if (path == _title) return;
    setState(() {
      _previous = _title;
      _title = path;
    });
    _controller.forward(from: 0);
  }

  void _pushDemo() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: SlideOverPageTransition.duration,
        reverseTransitionDuration: SlideOverPageTransition.reverseDuration,
        pageBuilder: (context, _, _) => Surface(
          color: context.colorScheme.surfaceContainerHigh,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text('Pushed route', style: AppTextStyle.title2.of(context)),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Pop'),
                ),
              ],
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondary, child) =>
            SlideOverPageTransition(
              animation: animation,
              secondaryAnimation: secondary,
              dragged: false,
              uncoveredByGesture: false,
              child: child,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        Section(
          title: 'AppTooltip and Tooltip',
          caption: 'Hover for AppTooltip; Tooltip opens on tap here.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              SegmentedControl<AppTooltipPlacement>(
                segments: [
                  for (final placement in AppTooltipPlacement.values)
                    (placement, placement.name),
                ],
                value: _placement,
                onChanged: (value) => setState(() => _placement = value),
              ),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AppTooltip(
                      message: 'AppTooltip, placement ${_placement.name}',
                      placement: _placement,
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('AppTooltip'),
                      ),
                    ),
                    const Text('withAppTooltip')
                        .withAppTooltip('Added by the theme helper'),
                    Tooltip(
                      message: 'Prism Tooltip',
                      triggerMode: TooltipTriggerMode.tap,
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('Tooltip'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Section(
          title: 'NavigationTitle',
          caption: 'Last selected: $_clicked. Segments are links.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Controls(
                children: [
                  for (final path in _paths)
                    TextButton(onPressed: () => _go(path), child: Text(path)),
                ],
              ),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 56,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => NavigationTitle(
                      previous: _previous,
                      title: _title,
                      progress: _controller.value,
                      previousStyle: AppTextStyle.headline.of(context),
                      style: AppTextStyle.headline.of(context),
                      onSelect: (index) =>
                          setState(() => _clicked = _title.split(' › ')[index]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Section(
          title: 'SlideOverPageTransition',
          child: Controls(
            children: [
              FilledButton(
                onPressed: _pushDemo,
                child: const Text('Push demo route'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
