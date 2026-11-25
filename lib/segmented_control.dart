import 'dart:ui' show ImageFilter;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:prism_ui/button.dart';
import 'package:prism_ui/card_surface.dart';
import 'package:prism_ui/context.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/liquid_glass.dart';
import 'package:prism_ui/measure.dart';
import 'package:prism_ui/metrics.dart';
import 'package:prism_ui/navigation_dock.dart';
import 'package:prism_ui/press_surface.dart';
import 'package:prism_ui/shape.dart';
import 'package:prism_ui/surface.dart';
import 'package:prism_ui/text_style.dart';
import 'package:prism_ui/typography.dart';

const _slideDuration = Duration(milliseconds: 250);
const _slideCurve = Curves.easeOutCubic;

class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.size,
    this.stretches = false,
  }) : assert(!stretches || size != null, 'only a sized control stretches');

  static const double _inset = 4;
  static const double _sizedInset = 2;
  static int _labelInsetOf(TonalButtonSize size) =>
      size == TonalButtonSize.compact ? 10 : 14;

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Stands as tall as this button size, each segment as wide as its label.
  final TonalButtonSize? size;

  /// Shares the width it is given equally among the segments at [size]'s
  /// height, where a sized control fits each segment to its label.
  final bool stretches;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final count = segments.length;
    final index = segments.indexWhere((segment) => segment.$1 == value);
    final size = this.size;
    final labelStyle = size == TonalButtonSize.compact
        ? AppTextStyle.footnote
        : AppTextStyle.subheadline;
    TextStyle styleOf({required bool emphasized}) {
      final style = labelStyle.of(context, emphasized: emphasized);
      return size == null ? style : style.toTabular;
    }

    final inset = size == null ? _inset : _sizedInset;
    List<int>? widths;
    if (size != null && !stretches) {
      final measure = MeasureScope.of(context);
      final style = styleOf(emphasized: true);
      widths = [
        for (final (_, label) in segments)
          measure.computeTextSize(Text(label, style: style)).width.ceil() +
              2 * _labelInsetOf(size),
      ];
    }
    Widget segment(T option, String label) => PressSurface(
      fill: const Color(0x00000000),
      shape: AppShape.full,
      look: option == value ? PressLook.none : PressLook.ink,
      ringStandsOff: option == value,
      selected: option == value,
      childFills: true,
      // A null onPressed would unfocus the selected segment.
      onPressed: option == value ? () {} : () => onChanged(option),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: context.motionDuration(_slideDuration),
          style: styleOf(emphasized: option == value).copyWith(
            color: option == value
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
    final thumb = DecoratedBox(
      decoration: ShapeDecoration(
        color: colorScheme.primary,
        shape: AppShape.full,
      ),
    );
    final shares = widths ?? List.filled(count, 1);
    final whole = shares.fold(0, (sum, share) => sum + share);
    return Container(
      width: widths == null ? null : whole + 2 * inset,
      height: size?.button ?? viewSwitcherHeight,
      padding: EdgeInsets.all(inset),
      decoration: ShapeDecoration(
        color: context.raisedSurfaceLevel.colorOf(colorScheme),
        shape: AppShape.full,
      ),
      child: Stack(
        children: [
          if (index >= 0)
            TweenAnimationBuilder<Rect?>(
              tween: RectTween(
                end: Rect.fromLTWH(
                  shares.take(index).fold(0, (sum, share) => sum + share) /
                      whole,
                  0,
                  shares[index] / whole,
                  1,
                ),
              ),
              duration: context.motionDuration(_slideDuration),
              curve: _slideCurve,
              builder: (context, span, child) => Align(
                alignment: AlignmentDirectional(
                  span!.width < 1 ? 2 * span.left / (1 - span.width) - 1 : 0,
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: span.width,
                  heightFactor: 1,
                  child: child,
                ),
              ),
              child: thumb,
            ),
          Row(
            children: [
              for (final (index, (option, label)) in segments.indexed)
                Expanded(flex: shares[index], child: segment(option, label)),
            ],
          ),
        ],
      ),
    );
  }
}

class GlyphSegment<T> {
  const GlyphSegment({
    required this.value,
    required this.glyph,
    required this.label,
  });

  final T value;
  final Glyph glyph;
  final String label;
}

/// Bouncy enough for the indicator to land with a little give, which the
/// pages beside it, travelling touching, cannot afford.
final glyphSegmentSpring = SpringDescription.withDurationAndBounce(
  duration: const Duration(milliseconds: 420),
  bounce: 0.18,
);

/// Moves [position] to [index] along [glyphSegmentSpring], keeping the speed
/// it had when a new index interrupts it.
void springToSegment(
  AnimationController position,
  int index, {
  bool instant = false,
}) {
  if (instant) {
    position.value = index.toDouble();
    return;
  }
  position.animateWith(
    SpringSimulation(
      glyphSegmentSpring,
      position.value,
      index.toDouble(),
      position.velocity,
    ),
  );
}

/// Segments shown as glyphs under one indicator that slides between them;
/// [position] is the segment index it stands on, fractional while it moves,
/// so a title can travel with it.
class GlyphSegmentedControl<T> extends StatelessWidget {
  const GlyphSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.position,
    required this.onChanged,
  });

  static const double _inset = 4;
  static const double _segment = 56;
  static const _size = TonalButtonSize.section;

  final List<GlyphSegment<T>> segments;
  final T value;
  final AnimationController position;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => LiquidGlassScope(
    enabled: TonalButtonTheme.glassOf(context),
    quality: LiquidGlassScope.qualityOf(context),
    child: SizedBox(
      width: segments.length * _segment + _inset * 2,
      height: _size.button + _inset * 2,
      child: GestureDetector(
        onHorizontalDragUpdate: (_) {},
        child: FloatingNavigationBar(
          compact: true,
          position: position,
          destinations: [
            for (final segment in segments)
              NavigationDockDestination(
                id: segment.value,
                glyph: segment.glyph,
                label: segment.label,
              ),
          ],
          selectedIndex: segments.indexWhere(
            (segment) => segment.value == value,
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          onSelected: (index) => onChanged(segments[index].value),
        ),
      ),
    ),
  );
}

/// Labels stacked like an odometer: each rolls through as [position] passes
/// its index, the next arriving from below while moving forward.
class RollingTitle extends StatelessWidget {
  const RollingTitle({super.key, required this.labels, required this.position});

  final List<String> labels;
  final Animation<double> position;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: position,
    builder: (context, _) {
      final at = position.value;
      final nearest = at.round().clamp(0, labels.length - 1);
      return Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          for (var index = 0; index < labels.length; index++)
            if ((at - index).abs() < 1 || index == nearest)
              _rolling(labels[index], at - index, index == nearest),
        ],
      );
    },
  );

  Widget _rolling(String label, double distance, bool current) {
    final away = distance.abs().clamp(0.0, 1.0);
    return FractionalTranslation(
      translation: Offset(0, -distance * 0.9),
      child: Transform.scale(
        scale: 1 - away * 0.12,
        alignment: AlignmentDirectional.centerStart,
        child: Opacity(
          opacity: (1 - away * 1.4).clamp(0.0, 1.0),
          child: ImageFiltered(
            enabled: away > 0,
            imageFilter: ImageFilter.blur(sigmaY: away * 8),
            child: ExcludeSemantics(
              excluding: !current,
              child: Text(label, maxLines: 1, softWrap: false),
            ),
          ),
        ),
      ),
    );
  }
}
