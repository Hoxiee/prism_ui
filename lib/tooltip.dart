import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:prism_ui/context.dart';
import 'package:prism_ui/shape.dart';
import 'package:prism_ui/theme_data.dart';
import 'package:prism_ui/typography.dart';

/// A short message over a widget, shown by hovering or long pressing it.
class Tooltip extends StatelessWidget {
  const Tooltip({
    super.key,
    required this.message,
    this.preferBelow = true,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.excludeFromSemantics = false,
    required this.child,
  });

  final String message;
  final bool preferBelow;
  final TooltipTriggerMode triggerMode;
  final bool excludeFromSemantics;
  final Widget child;

  static const _verticalOffset = 24.0;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return child;
    }
    return RawTooltip(
      semanticsTooltip: excludeFromSemantics ? null : message,
      tooltipBuilder: (context, animation) => FadeTransition(
        opacity: animation,
        child: _TooltipBox(message: message),
      ),
      triggerMode: triggerMode,
      positionDelegate: (position) => positionDependentBox(
        size: position.overlaySize,
        childSize: position.tooltipSize,
        target: position.target,
        verticalOffset: _verticalOffset,
        preferBelow: preferBelow,
      ),
      ignorePointer: true,
      child: child,
    );
  }
}

class _TooltipBox extends StatelessWidget {
  const _TooltipBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final desktop = switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
    final dark = Theme.brightnessOf(context) == Brightness.dark;
    final style = AppTextStyle.subheadline
        .of(context)
        .copyWith(
          color: dark ? Colors.black : Colors.white,
          fontSize: desktop ? 12 : 14,
        );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: desktop ? 24 : 32),
      child: DefaultTextStyle(
        style: style,
        child: Container(
          decoration: ShapeDecoration(
            shape: AppShape.xs,
            color: dark ? const Color(0xE6FFFFFF) : const Color(0xE6616161),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 8 : 16,
            vertical: 4,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(message, style: style),
          ),
        ),
      ),
    );
  }
}

const _tooltipGap = 8.0;
const _tooltipSidePadding = 12.0;

abstract final class AppTooltipTiming {
  static const wait = Duration(milliseconds: 600);
  static const adjacent = Duration(milliseconds: 200);
  static const warm = Duration(seconds: 1);
  static const exit = Duration(milliseconds: 120);
  static const enterAnimation = Duration(milliseconds: 150);
  static const exitAnimation = Duration(milliseconds: 90);
  static const touch = Duration(seconds: 4);
}

/// What an [AppTooltip] is drawn with, so a host can reuse it for its own
/// overlays.
class AppTooltipThemeData {
  const AppTooltipThemeData({
    required this.constraints,
    required this.padding,
    required this.margin,
    required this.textStyle,
    required this.decoration,
  });

  final BoxConstraints constraints;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final TextStyle textStyle;
  final ShapeDecoration decoration;
}

AppTooltipThemeData appTooltipTheme(ThemeData theme) {
  final colors = theme.colorScheme;
  return AppTooltipThemeData(
    constraints: const BoxConstraints(minHeight: 32, maxWidth: 300),
    padding: const EdgeInsets.symmetric(
      horizontal: _tooltipSidePadding,
      vertical: _tooltipGap,
    ),
    margin: const EdgeInsets.all(_tooltipGap),
    textStyle: theme.footnoteText.copyWith(
      color: colors.onSurface,
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
    ),
    decoration: ShapeDecoration(
      color: colors.surfaceContainerHigh,
      shape: _TooltipShape(
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      shadows: [
        BoxShadow(
          color: colors.shadow.withValues(
            alpha: colors.brightness == Brightness.dark ? 0.24 : 0.1,
          ),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ],
    ),
  );
}

extension AppTooltipWidget on Widget {
  /// Wraps this widget in an [AppTooltip]; a null or empty [message] leaves it
  /// as it is.
  Widget withAppTooltip(String? message) {
    if (message == null || message.isEmpty) return this;
    return AppTooltip(message: message, child: this);
  }
}

class _TooltipShape extends OutlinedBorder {
  const _TooltipShape({super.side});

  OutlinedBorder _shape(Rect rect) =>
      AppShape.all(AppCorner.fit(rect.shortestSide)).copyWith(side: side);

  @override
  _TooltipShape copyWith({BorderSide? side}) =>
      _TooltipShape(side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => _TooltipShape(side: side.scale(t));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape(rect).getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape(rect).getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      _shape(rect).paint(canvas, rect, textDirection: textDirection);
}

/// Which edge of its target an [AppTooltip] anchors to.
enum AppTooltipPlacement { auto, above, below, left, right }

class AppTooltip extends StatefulWidget {
  const AppTooltip({
    super.key,
    required this.message,
    this.preferBelow = false,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.hoverDelayScale = 1,
    this.placement = AppTooltipPlacement.auto,
    required this.child,
  });

  final String? message;
  final bool preferBelow;
  final TooltipTriggerMode triggerMode;

  /// Scales the hover delay for this tooltip only, leaving the shared
  /// [AppTooltipTiming] untouched. 2 waits twice as long before showing.
  final double hoverDelayScale;

  /// Which edge of the target the tooltip anchors to. [AppTooltipPlacement.auto]
  /// keeps the default above/below behaviour and honours [preferBelow]; every
  /// placement flips to the opposite edge when the chosen one has no room.
  final AppTooltipPlacement placement;
  final Widget child;

  @override
  State<AppTooltip> createState() => _AppTooltipState();
}

class _AppTooltipState extends State<AppTooltip>
    with SingleTickerProviderStateMixin {
  static final _session = _TooltipSession();

  final _tooltipKey = GlobalKey<RawTooltipState>();
  late final _entry = AnimationController(vsync: this);
  late final _entrance = CurvedAnimation(
    parent: _entry,
    curve: Curves.easeOutCubic,
  );
  Animation<double>? _nativeAnimation;
  ScrollPosition? _scrollPosition;
  Timer? _wait;
  bool _enabled = true;
  bool _hovered = false;
  bool _focused = false;

  // Alpha gates this on its FocusHighlightVisibility notifier; the repo has
  // no such primitive, so read the highlight mode live, as the list rows do.
  bool get _keyboardFocused =>
      _focused &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    _session.attach(this);
    FocusManager.instance.addListener(_updateFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entry.duration = context.motionDuration(AppTooltipTiming.enterAnimation);
    _enabled = ModalRoute.isCurrentOf(context) ?? true;
    if (!_enabled) _session.cancel(this);
    final position = Scrollable.maybeOf(context)?.position;
    if (_scrollPosition != position) {
      _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
      _scrollPosition = position;
      position?.isScrollingNotifier.addListener(_handleScroll);
    }
  }

  @override
  void didUpdateWidget(covariant AppTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message?.isEmpty ?? true) _session.cancel(this);
  }

  void _handleScroll() {
    if (_scrollPosition?.isScrollingNotifier.value ?? false) {
      _session.interrupt();
    }
  }

  void _request({bool keyboard = false}) {
    if (!_enabled || (widget.message?.isEmpty ?? true)) return;
    if (!keyboard && !_session.allowHover) return;
    if (_session.pending == this || _session.active == this) return;
    if (!_session.claim(this)) return;
    _entry.reset();
    final hoverDelay = widget.hoverDelayScale == 1
        ? _session.hoverDelay
        : _session.hoverDelay * widget.hoverDelayScale;
    _wait = Timer(keyboard ? AppTooltipTiming.wait : hoverDelay, () {
      _wait = null;
      if (_enabled && (_hovered || _keyboardFocused)) _show();
    });
  }

  void _show({bool fromTouch = false}) {
    if (!_enabled) return;
    _wait?.cancel();
    _wait = null;
    _session.activate(this);
    if (!fromTouch) _tooltipKey.currentState?.ensureTooltipVisible();
    _entry.forward(from: 0);
  }

  void _cancelPresentation() {
    _wait?.cancel();
    _wait = null;
    _entry.reset();
  }

  void _enter(PointerEnterEvent event) {
    _hovered = true;
    _request();
  }

  void _hover(PointerHoverEvent event) {
    _session.allowHover = true;
    _request();
  }

  void _exit(PointerExitEvent event) {
    _hovered = false;
    if (_keyboardFocused) {
      scheduleMicrotask(() {
        if (mounted && _keyboardFocused && _session.active == this) {
          _tooltipKey.currentState?.ensureTooltipVisible();
        }
      });
    } else if (_session.pending == this) {
      _session.cancel(this);
    }
  }

  void _updateFocus() {
    if (_keyboardFocused) {
      _request(keyboard: true);
    } else if (!_hovered) {
      _session.cancel(this);
    }
  }

  void _nativeStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _session.release(this);
  }

  Widget _buildTooltip(BuildContext context, Animation<double> animation) {
    if (_nativeAnimation != animation) {
      _nativeAnimation?.removeStatusListener(_nativeStatusChanged);
      _nativeAnimation = animation..addStatusListener(_nativeStatusChanged);
    }
    final theme = appTooltipTheme(Theme.of(context));
    final surface = Padding(
      padding: theme.margin,
      child: ConstrainedBox(
        constraints: theme.constraints,
        child: DecoratedBox(
          decoration: theme.decoration,
          child: Padding(
            padding: theme.padding,
            child: Text(
              widget.message!,
              style: theme.textStyle,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([animation, _entrance]),
      child: surface,
      builder: (context, child) {
        if (_entry.isDismissed) return const SizedBox.shrink();
        return Opacity(
          opacity: math.min(animation.value, _entrance.value),
          child: Transform.translate(
            offset: Offset(0, (1 - _entrance.value) * 3),
            child: child,
          ),
        );
      },
    );
  }

  Offset _position(TooltipPositionContext context) {
    switch (widget.placement) {
      case AppTooltipPlacement.left:
        return _beside(context, toRight: false);
      case AppTooltipPlacement.right:
        return _beside(context, toRight: true);
      case AppTooltipPlacement.auto:
      case AppTooltipPlacement.above:
      case AppTooltipPlacement.below:
        return positionDependentBox(
          size: context.overlaySize,
          childSize: context.tooltipSize,
          target: context.target,
          verticalOffset: context.targetSize.height / 2,
          preferBelow: switch (widget.placement) {
            AppTooltipPlacement.below => true,
            AppTooltipPlacement.above => false,
            _ => widget.preferBelow,
          },
          margin: _tooltipGap,
        );
    }
  }

  Offset _beside(TooltipPositionContext context, {required bool toRight}) {
    final overlay = context.overlaySize;
    final tooltip = context.tooltipSize;
    final target = context.target;
    const margin = _tooltipGap;
    final gap = context.targetSize.width / 2 + margin;
    final rightX = target.dx + gap;
    final leftX = target.dx - gap - tooltip.width;
    final fitsRight = rightX + tooltip.width <= overlay.width - margin;
    final fitsLeft = leftX >= margin;
    // Flip to the opposite edge only when the preferred one cannot seat it.
    var x = toRight ? rightX : leftX;
    if (toRight && !fitsRight && fitsLeft) x = leftX;
    if (!toRight && !fitsLeft && fitsRight) x = rightX;
    final maxX = math.max(margin, overlay.width - tooltip.width - margin);
    final maxY = math.max(margin, overlay.height - tooltip.height - margin);
    return Offset(
      x.clamp(margin, maxX),
      (target.dy - tooltip.height / 2).clamp(margin, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message?.isEmpty ?? true) {
      return widget.child;
    }
    return MouseRegion(
      onEnter: _enter,
      onHover: _hover,
      onExit: _exit,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) {
          _focused = focused;
          _updateFocus();
        },
        child: RawTooltip(
          key: _tooltipKey,
          semanticsTooltip: widget.message,
          tooltipBuilder: _buildTooltip,
          positionDelegate: _position,
          triggerMode: widget.triggerMode,
          onTriggered: () => _show(fromTouch: true),
          touchDelay: AppTooltipTiming.touch,
          dismissDelay: AppTooltipTiming.exit,
          animationStyle: AnimationStyle(
            duration: Duration.zero,
            reverseDuration: context.motionDuration(
              AppTooltipTiming.exitAnimation,
            ),
            curve: Curves.easeOutCubic,
          ),
          child: widget.child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _wait?.cancel();
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    FocusManager.instance.removeListener(_updateFocus);
    _nativeAnimation?.removeStatusListener(_nativeStatusChanged);
    _session.detach(this);
    _entrance.dispose();
    _entry.dispose();
    super.dispose();
  }
}

class _TooltipSession with WidgetsBindingObserver {
  final _members = <_AppTooltipState>{};
  _AppTooltipState? pending;
  _AppTooltipState? active;
  Timer? _cooldown;
  bool _warm = false;
  bool allowHover = true;

  Duration get hoverDelay => active != null || _warm
      ? AppTooltipTiming.adjacent
      : AppTooltipTiming.wait;

  void attach(_AppTooltipState tooltip) {
    if (_members.isEmpty) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
      FocusManager.instance.addEarlyKeyEventHandler(_key);
      WidgetsBinding.instance.addObserver(this);
    }
    _members.add(tooltip);
  }

  void detach(_AppTooltipState tooltip) {
    if (pending == tooltip) pending = null;
    if (active == tooltip) active = null;
    _members.remove(tooltip);
    if (_members.isEmpty) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointer);
      FocusManager.instance.removeEarlyKeyEventHandler(_key);
      WidgetsBinding.instance.removeObserver(this);
      _cooldown?.cancel();
      _cooldown = null;
      _warm = false;
      allowHover = true;
    }
  }

  bool claim(_AppTooltipState tooltip) {
    final previous = pending ?? active;
    if (previous != null && previous != tooltip) {
      var ancestor = false;
      previous.context.visitAncestorElements((element) {
        ancestor = element == tooltip.context;
        return !ancestor;
      });
      if (ancestor && previous._hovered) return false;
    }
    pending?._cancelPresentation();
    pending = tooltip;
    return true;
  }

  void activate(_AppTooltipState tooltip) {
    if (pending != tooltip) pending?._cancelPresentation();
    pending = null;
    if (active != tooltip) active?._cancelPresentation();
    RawTooltip.dismissAllToolTips();
    active = tooltip;
  }

  void release(_AppTooltipState tooltip) {
    if (active != tooltip) return;
    active = null;
    _warm = true;
    _cooldown?.cancel();
    _cooldown = Timer(AppTooltipTiming.warm, () => _warm = false);
  }

  void cancel(_AppTooltipState tooltip) {
    if (pending == tooltip) pending = null;
    tooltip._cancelPresentation();
    if (active == tooltip) {
      release(tooltip);
      RawTooltip.dismissAllToolTips();
    }
  }

  void interrupt() {
    pending?._cancelPresentation();
    active?._cancelPresentation();
    pending = null;
    active = null;
    _cooldown?.cancel();
    _cooldown = null;
    _warm = false;
    allowHover = false;
    RawTooltip.dismissAllToolTips();
  }

  void _pointer(PointerEvent event) {
    if (event is PointerDownEvent ||
        event is PointerSignalEvent ||
        event is PointerPanZoomStartEvent) {
      interrupt();
    }
  }

  KeyEventResult _key(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        (pending != null || active != null)) {
      interrupt();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      interrupt();
    }
    return KeyEventResult.ignored;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) interrupt();
  }
}
