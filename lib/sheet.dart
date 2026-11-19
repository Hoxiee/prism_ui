import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:prism_ui/l10n.dart';
import 'package:prism_ui/color.dart';
import 'package:prism_ui/context.dart';
import 'package:prism_ui/inherited.dart';
import 'package:prism_ui/navigator.dart';
import 'package:prism_ui/shape.dart';
import 'package:prism_ui/view_scope.dart';

import 'form_sheet.dart';
import 'sheet_navigator.dart';
import 'side_sheet.dart';
import 'snap_sheet.dart';

@immutable
class SheetProps {
  final Color? backgroundColor;

  final List<double> detents;

  const SheetProps({this.backgroundColor, this.detents = snapSheetDetents});
}

@immutable
class ExtendProps {
  final bool forceFull;

  const ExtendProps({this.forceFull = false});
}

enum SheetType {
  page,
  bottomSheet,
  sideSheet,
  formSheet;

  bool get isCompact => this == bottomSheet || this == formSheet;
}

const _compactSheetMaxWidth = 600.0;

bool _usesBottomSheet(BuildContext context) =>
    ViewScope.sizeOf(context).width <= _compactSheetMaxWidth;

/// A sheet shrinks back about its top behind a sheet that rises over it, and
/// shows this much of itself above that one, as iOS 27's do.
const stackedSheetPeek = 10.0;
const stackedSheetScale = 0.9204;

const _sheetCorner = 38.0;

const sheetFloatInset = 8.0;

/// A foot rounder than a square display's corners would show beside it;
/// where the platform reports no corners, a floating foot matches the top.
BorderRadius floatingSheetRadius(BorderRadius? display, double float) {
  final corners = display ?? BorderRadius.zero;
  Radius top(Radius corner) => Radius.circular(
    corner.x > 0 ? math.min(corner.x, _sheetCorner) : AppCorner.xxl,
  );
  Radius foot(Radius corner) => Radius.circular(
    lerpDouble(
      math.min(corner.x, _sheetCorner),
      corner.x > 0 ? _sheetCorner : AppCorner.xxl,
      float,
    )!,
  );
  return BorderRadius.only(
    topLeft: top(corners.topLeft),
    topRight: top(corners.topRight),
    bottomLeft: foot(corners.bottomLeft),
    bottomRight: foot(corners.bottomRight),
  );
}

BorderRadius bottomSheetRadiusOf(BuildContext context) =>
    floatingSheetRadius(MediaQuery.displayCornerRadiiOf(context), 0);

class SheetCornersScope
    extends InheritedNotifier<ValueListenable<BorderRadius>> {
  const SheetCornersScope({
    super.key,
    required ValueListenable<BorderRadius> corners,
    required super.child,
  }) : super(notifier: corners);

  static BorderRadius? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SheetCornersScope>()
      ?.notifier
      ?.value;
}

Future<T?> showSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  SheetProps props = const SheetProps(),
}) {
  return _showAdaptiveSheet<T>(
    context,
    builder: (context, _) => builder(context),
    props: props,
    fitsContent: true,
  );
}

/// Opens a form: a bottom sheet in a narrow window, and elsewhere a card
/// centered over the navigator, as iPad and macOS present a form sheet.
Future<T?> showFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  SheetProps props = const SheetProps(),
}) {
  return _showAdaptiveSheet<T>(
    context,
    builder: (context, _) => builder(context),
    props: props,
    fitsContent: true,
    form: true,
  );
}

Future<T?> _showSideSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? backgroundColor,
}) {
  return showModalSideSheet<T>(
    context: context,
    backgroundColor: backgroundColor,
    barrierColor: context.colorScheme.modalScrim,
    builder: (sheetContext) {
      return SheetProvider(
        type: SheetType.sideSheet,
        child: builder(sheetContext),
      );
    },
  );
}

Future<T?> showExtend<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  ExtendProps props = const ExtendProps(),
}) {
  final isMobile = _usesBottomSheet(context);
  return switch (isMobile || props.forceFull) {
    true => BaseNavigator.push(
      context,
      SheetProvider(type: SheetType.page, child: builder(context)),
    ),
    false => _showSideSheet<T>(context, builder: builder),
  };
}

/// Opens a sheet the reader can drag between [snapSheetDetents], starting at
/// the shortest. Where a sheet cannot have detents the content keeps its own
/// scroll controller.
Future<T?> showSnapSheet<T>(
  BuildContext context, {
  required SnapSheetBuilder builder,
}) {
  return _showAdaptiveSheet<T>(context, builder: builder);
}

/// The sheet follows the view across the bottom sheet width: it reopens in the
/// other form, and the result is whichever form the reader closes.
Future<T?> _showAdaptiveSheet<T>(
  BuildContext context, {
  required SnapSheetBuilder builder,
  SheetProps props = const SheetProps(),
  bool fitsContent = false,
  bool form = false,
}) {
  final completer = Completer<T?>();
  final contentKey = GlobalKey();
  final barrierColor = context.colorScheme.modalScrim;
  final barrierLabel = UiLocalizations.of(context).close;

  void open({required bool isMobile, Route<T>? replacing}) {
    var crossed = false;
    var popped = false;
    late final ModalRoute<T> route;

    // The mobile layout drops a desktop page's navigator, sheet and all.
    void reopenIfDropped() {
      if (crossed || popped) {
        return;
      }
      crossed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          open(isMobile: _usesBottomSheet(context));
        } else {
          completer.complete();
        }
      });
    }

    Widget home(BuildContext sheetContext, ScrollController? _) {
      return _AdaptiveSheetHome(
        isMobile: isMobile,
        onCross: () {
          if (crossed || popped || !sheetContext.mounted) {
            return;
          }
          if (!route.isCurrent) {
            return;
          }
          final usesBottomSheet = _usesBottomSheet(sheetContext);
          if (usesBottomSheet == isMobile) {
            return;
          }
          crossed = true;
          open(isMobile: usesBottomSheet, replacing: route);
        },
        onDispose: reopenIfDropped,
        child: SheetScrollScope(
          createController: createSheetScrollController,
          child: _AdaptiveSheetContent(
            key: contentKey,
            builder: builder,
            providesController: isMobile && !fitsContent,
          ),
        ),
      );
    }

    if (isMobile) {
      route = SnapSheetRoute<T>(
        builder: home,
        detents: props.detents,
        fitsContent: fitsContent,
        sheetBarrierColor: barrierColor,
        barrierLabel: barrierLabel,
      );
    } else if (form) {
      route = FormSheetRoute<T>(
        builder: (context) => home(context, null),
        backgroundColor: props.backgroundColor,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
      );
    } else {
      route = ModalSideSheetRoute<T>(
        builder: (context) => SheetProvider(
          type: SheetType.sideSheet,
          child: home(context, null),
        ),
        backgroundColor: props.backgroundColor,
        modalBarrierColor: barrierColor,
        barrierLabel: barrierLabel,
        barrierOnTapHint: barrierLabel,
      );
    }
    if (replacing == null) {
      sheetNavigatorOf(context).push(route);
    } else {
      replacing.navigator!.replace(oldRoute: replacing, newRoute: route);
    }
    unawaited(
      route.popped.then((value) {
        popped = true;
        if (!crossed) {
          completer.complete(value);
        }
      }),
    );
  }

  open(isMobile: _usesBottomSheet(context));
  return completer.future;
}

class _AdaptiveSheetContent extends StatefulWidget {
  const _AdaptiveSheetContent({
    super.key,
    required this.builder,
    required this.providesController,
  });

  final SnapSheetBuilder builder;
  final bool providesController;

  @override
  State<_AdaptiveSheetContent> createState() => _AdaptiveSheetContentState();
}

class _AdaptiveSheetContentState extends State<_AdaptiveSheetContent> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.providesController
        ? _controller ??= createSheetScrollController()
        : null;
    return widget.builder(context, controller);
  }
}

class _AdaptiveSheetHome extends StatefulWidget {
  const _AdaptiveSheetHome({
    required this.isMobile,
    required this.onCross,
    required this.onDispose,
    required this.child,
  });

  final bool isMobile;
  final VoidCallback onCross;
  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_AdaptiveSheetHome> createState() => _AdaptiveSheetHomeState();
}

class _AdaptiveSheetHomeState extends State<_AdaptiveSheetHome> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_usesBottomSheet(context) != widget.isMobile &&
        ModalRoute.isCurrentOf(context) == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCross());
    }
    // A sheet is not under the page's floating dock, which sits behind it.
    return BottomInsetScope(inset: 0, child: widget.child);
  }
}
