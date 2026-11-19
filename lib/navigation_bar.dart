import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:prism_ui/context.dart';
import 'package:prism_ui/motion.dart';
import 'package:prism_ui/navigation_dock.dart'
    show NavigationDestinationLabelBehavior;
import 'package:prism_ui/press_region.dart';
import 'package:prism_ui/shape.dart';
import 'package:prism_ui/surface.dart';
import 'package:prism_ui/typography.dart';

class NavigationDestination {
  const NavigationDestination({required this.icon, required this.label});

  final Widget icon;
  final String label;
}

/// The bar a window's tabs stand on where the floating dock is turned off.
class NavigationBar extends StatelessWidget {
  const NavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.labelBehavior = NavigationDestinationLabelBehavior.alwaysShow,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final NavigationDestinationLabelBehavior labelBehavior;

  static const _height = 80.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Surface(
      color: SurfaceLevel.floatingOf(colorScheme).colorOf(colorScheme),
      child: SafeArea(
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              for (final (index, destination) in destinations.indexed)
                Expanded(
                  child: _Destination(
                    destination: destination,
                    selected: index == selectedIndex,
                    labelBehavior: labelBehavior,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.destination,
    required this.selected,
    required this.labelBehavior,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final NavigationDestinationLabelBehavior labelBehavior;
  final VoidCallback onTap;

  static const _indicator = Size(64, 32);
  static const _motion = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final floating = SurfaceLevel.floatingOf(colorScheme);
    final showLabel = switch (labelBehavior) {
      NavigationDestinationLabelBehavior.alwaysShow => true,
      NavigationDestinationLabelBehavior.alwaysHide => false,
      NavigationDestinationLabelBehavior.onlyShowSelected => selected,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: showLabel ? null : destination.label,
      container: true,
      child: PressRegion(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            SizedBox.fromSize(
              size: _indicator,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: selected ? 1 : 0),
                    duration: context.motionDuration(_motion),
                    curve: Curves.easeInOutCubicEmphasized,
                    builder: (context, t, _) => Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scaleX: t,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: floating.next.colorOf(colorScheme),
                            shape: AppShape.full,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  IconTheme.merge(
                    data: IconThemeData(
                      size: 24,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    child: destination.icon,
                  ),
                ],
              ),
            ),
            if (showLabel)
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption1
                    .of(context, emphasized: true)
                    .copyWith(
                      color: selected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class NavigationBarEntry {
  const NavigationBarEntry({
    required this.id,
    required this.icon,
    required this.label,
    this.group = 0,
  });

  final Object id;
  final Widget icon;
  final String label;
  final int group;
}

/// A [NavigationBar] whose set of destinations can change, crossfading and
/// resizing between sets and marking the boundary between groups.
class AnimatedNavigationBar extends StatelessWidget {
  const AnimatedNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.labelBehavior = NavigationDestinationLabelBehavior.alwaysShow,
  });

  final List<NavigationBarEntry> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final NavigationDestinationLabelBehavior labelBehavior;

  @override
  Widget build(BuildContext context) {
    final duration = context.disableAnimations
        ? Duration.zero
        : fadeTabDuration;
    final colorScheme = context.colorScheme;
    final Widget bar = destinations.isEmpty
        ? const SizedBox.shrink()
        : Stack(
            children: [
              NavigationBar(
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: destination.icon,
                      label: destination.label,
                    ),
                ],
                selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
                onDestinationSelected: onSelected,
                labelBehavior: labelBehavior,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        for (final (index, destination) in destinations.indexed)
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child:
                                  index > 0 &&
                                      destination.group !=
                                          destinations[index - 1].group
                                  ? SizedBox(
                                      width: 1,
                                      height: 24,
                                      child: ColoredBox(
                                        color: colorScheme.outlineVariant,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
    if (context.disableAnimations) return bar;
    return AnimatedSize(
      duration: duration,
      alignment: Alignment.bottomCenter,
      curve: fadeTabCurve,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: fadeTabCurve,
        switchOutCurve: fadeTabCurve,
        layoutBuilder: (current, outgoing) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            for (final child in outgoing)
              IgnorePointer(
                child: ExcludeSemantics(
                  child: ExcludeFocus(
                    child: TickerMode(enabled: false, child: child),
                  ),
                ),
              ),
            ?current,
          ],
        ),
        child: KeyedSubtree(
          key: ValueKey(
            _DestinationSet([for (final item in destinations) item.id]),
          ),
          child: bar,
        ),
      ),
    );
  }
}

class _DestinationSet {
  const _DestinationSet(this.ids);

  final List<Object> ids;

  @override
  bool operator ==(Object other) =>
      other is _DestinationSet && listEquals(ids, other.ids);

  @override
  int get hashCode => Object.hashAll(ids);
}
