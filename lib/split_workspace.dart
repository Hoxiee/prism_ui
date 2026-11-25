import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:prism_ui/context.dart';
import 'package:prism_ui/deferred_push.dart';
import 'package:prism_ui/drag_back.dart';
import 'package:prism_ui/inherited.dart';
import 'package:prism_ui/keyboard_inset_hold.dart';
import 'package:prism_ui/page_background.dart';
import 'package:prism_ui/page_transition.dart';
import 'package:prism_ui/page_viewport.dart';
import 'package:prism_ui/pop_scope.dart';
import 'package:prism_ui/surface.dart';
import 'package:prism_ui/tab_motion.dart';
import 'package:prism_ui/text_selection_controls.dart';
import 'package:prism_ui/view_scope.dart';

const _placeholderKey = ValueKey('split-workspace.placeholder');

String _joinTitles(Iterable<String> titles) => titles.join(' › ');

/// One page of a [SplitWorkspace]'s detail pane. [id] identifies the page
/// across rebuilds and pops; [title] is its segment in the path header.
class SplitWorkspacePage {
  const SplitWorkspacePage({
    required this.id,
    required this.title,
    required this.child,
  });

  final Object id;
  final String title;
  final Widget child;
}

/// Drives a [SplitWorkspace] from outside its build: the app owns the list of
/// pages, while detail pages and editor routes live on the workspace's own
/// navigator.
class SplitWorkspaceController {
  SplitWorkspaceController({this.detailTitle});

  /// The title of a detail route's own content, appended to its parent path.
  String? Function(BuildContext? context)? detailTitle;

  final _navigator = GlobalKey<NavigatorState>();
  final _observer = _SplitWorkspaceRouteObserver();
  var _navigating = false;
  var _split = false;
  _SplitWorkspaceState? _host;

  /// Whether the workspace currently shows the catalog beside its detail pane.
  bool get isSplit => _split;

  /// The topmost route, a page or a detail page pushed over one.
  Route<dynamic>? get topRoute => _observer.top;

  /// The routes of the pages the app passed, in order, without the
  /// placeholder that stands in for an empty catalog.
  Iterable<Route<dynamic>> get pageRoutes => _observer.pages;

  bool get canPop => _navigator.currentState?.canPop() ?? false;

  /// Pops the top route, telling whether there was one.
  Future<bool> maybePop() async {
    final navigator = _navigator.currentState;
    if (navigator == null || !navigator.canPop()) return false;
    await navigator.maybePop();
    return true;
  }

  /// Pops routes a page pushed over its own, such as editors, down to [until],
  /// asking each exit guard first. Returns whether every exit was allowed.
  Future<bool> dismissEditors({Route<dynamic>? until}) async {
    final navigator = _navigator.currentState;
    while (navigator != null &&
        _observer.top?.settings is! Page &&
        !identical(_observer.top, until) &&
        navigator.canPop()) {
      final previous = _observer.top;
      if (previous == null || !await canLeaveRoute(previous) || !_mounted) {
        return false;
      }
      if (previous.isActive) navigator.pop();
      if (identical(previous, _observer.top)) return false;
    }
    return _mounted;
  }

  /// Pushes [page] over [context]'s route as one more step of the workspace
  /// path. Returns null when [context] is not on this workspace's navigator.
  Future<T?>? pushDetail<T>(
    BuildContext context,
    Widget page, {
    String? parent,
    bool? parentHasBack,
  }) {
    final navigator = _navigator.currentState;
    final below = ModalRoute.of(context);
    if (navigator == null ||
        below == null ||
        !identical(Navigator.of(context), navigator)) {
      return null;
    }
    return navigator.push<T>(
      _SplitWorkspaceDetailRoute<T>(
        host: this,
        parent: parent ?? pathOf(below),
        parentHasBack:
            parentHasBack ??
            (below is _SplitWorkspaceDetailRoute ||
                _observer.pages.contains(below)),
        page: page,
        backdrop: _host?.widget.backdrop ?? const PageBackdrop(),
      ),
    );
  }

  /// The path header of [route], ending in its own title where it has one.
  String? pathOf(Route<dynamic>? route) {
    if (route is _SplitWorkspaceDetailRoute) {
      final segments = [
        ?route.parent,
        ?detailTitle?.call(route.subtreeContext),
      ];
      return segments.isEmpty ? null : _joinTitles(segments);
    }
    if (route == null || _SplitWorkspaceRouteObserver.isPlaceholder(route)) {
      return null;
    }
    final settings = route.settings;
    return settings is _SplitWorkspaceRoutePage ? settings.headerTitle : null;
  }

  /// Forgets the host workspace; call from the app when it stops showing it.
  void dispose() {
    _host = null;
    _split = false;
  }

  bool get _mounted => _host?.mounted ?? false;

  void _attach(_SplitWorkspaceState host) {
    _host = host;
    _split = host._split;
  }

  void _detach(_SplitWorkspaceState host) {
    if (identical(_host, host)) {
      _host = null;
      _split = false;
    }
  }

  Future<void> _popTo(int depth) async {
    if (_navigating) return;
    _navigating = true;
    try {
      if (!await dismissEditors()) return;
      for (final previous in _observer.pages.skip(depth).toList().reversed) {
        if (!await canLeaveRoute(previous) || !_mounted) return;
      }
      await _host?.widget.onPopTo(depth);
    } finally {
      _navigating = false;
    }
  }

  Future<void> _popToDetail(Route<dynamic> target) async {
    if (_navigating) return;
    _navigating = true;
    try {
      await dismissEditors(until: target);
    } finally {
      _navigating = false;
    }
  }

  void _selectPathSegment(int index) {
    if (index < _observer.pages.length) {
      unawaited(_popTo(index + 1));
      return;
    }
    final target = _observer._routes
        .whereType<_SplitWorkspaceDetailRoute<dynamic>>()
        .where((route) => route.depth == index)
        .lastOrNull;
    if (target != null) unawaited(_popToDetail(target));
  }
}

/// A master-detail shell: a catalog pane beside a detail pane whose pages the
/// app supplies, promoting to two panes once there is room for both.
class SplitWorkspace extends StatefulWidget {
  const SplitWorkspace({
    super.key,
    required this.controller,
    required this.catalog,
    this.landing,
    required this.pages,
    required this.catalogTitle,
    required this.landingTitle,
    required this.onPopTo,
    required this.onRemoved,
    this.detailTitle,
    this.backdrop = const PageBackdrop(),
    this.minWidth = 960,
    this.minCssWidth = 800,
    this.minHeight = 480,
    this.catalogWidth = 360,
    this.maxBodyWidth = 840,
  });

  /// Divides the catalog from the detail pane in the split layout.
  static const dividerKey = ValueKey('split-workspace.divider');

  final SplitWorkspaceController controller;

  /// The catalog pane, shown alone in the compact layout.
  final Widget catalog;

  /// What the detail pane shows while [pages] is empty.
  final Widget? landing;

  final List<SplitWorkspacePage> pages;

  /// The header of the catalog in the compact layout.
  final String catalogTitle;

  /// The header of the detail pane while [pages] is empty.
  final String landingTitle;

  /// Pops [pages] down to `depth`; the app owns that list.
  final Future<void> Function(int depth) onPopTo;

  /// A page the navigator removed on its own, identified by its [id].
  final ValueChanged<Object> onRemoved;

  /// The title of a detail route's own content, appended to its parent path.
  final String? Function(BuildContext? context)? detailTitle;

  /// Painted under a route as it slides in, so the pages beneath stay hidden.
  final Widget backdrop;

  /// The pane width below which the workspace shows one pane.
  final double minWidth;

  /// The pane width per text scale below which the workspace shows one pane.
  final double minCssWidth;

  final double minHeight;
  final double catalogWidth;
  final double maxBodyWidth;

  @override
  State<SplitWorkspace> createState() => _SplitWorkspaceState();
}

class _SplitWorkspaceState extends State<SplitWorkspace> {
  var _split = false;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _syncDetailTitle();
  }

  @override
  void didUpdateWidget(SplitWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
    _syncDetailTitle();
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  void _syncDetailTitle() {
    final detailTitle = widget.detailTitle;
    if (detailTitle != null) widget.controller.detailTitle = detailTitle;
  }

  void _setSplit(bool split) {
    _split = split;
    widget.controller._split = split;
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    final navigation = NavigationDockScope.maybeOf(context);
    final parent = context.getInheritedWidgetOfExactType<ViewScope>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final split =
            constraints.maxWidth >= widget.minWidth &&
            constraints.maxWidth / textScale >= widget.minCssWidth &&
            constraints.maxHeight >= widget.minHeight;
        _setSplit(split);
        final catalogWidth = split ? widget.catalogWidth : constraints.maxWidth;
        final detailStart = split ? catalogWidth + 1 : 0.0;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final workspace = PageBackground(
          baseColor: SurfaceLevel.page.colorOf(context.colorScheme),
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: catalogWidth,
                child: split
                    ? PageViewport(
                        routeHeader: true,
                        bounds: Rect.fromLTWH(
                          rtl ? constraints.maxWidth - catalogWidth : 0,
                          0,
                          catalogWidth,
                          constraints.maxHeight,
                        ),
                        child: widget.catalog,
                      )
                    : const SizedBox.shrink(),
              ),
              if (split)
                PositionedDirectional(
                  start: catalogWidth,
                  top: 0,
                  bottom: 0,
                  width: 1,
                  child: TabContentMotion.wrap(
                    context,
                    ColoredBox(
                      key: SplitWorkspace.dividerKey,
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              PositionedDirectional(
                start: detailStart,
                end: 0,
                top: 0,
                bottom: 0,
                child: PageViewport(
                  routeHeader: split,
                  inlineHeaders: !split,
                  bounds: Rect.fromLTWH(
                    rtl ? 0 : detailStart,
                    0,
                    constraints.maxWidth - detailStart,
                    constraints.maxHeight,
                  ),
                  child: Navigator(
                    key: widget.controller._navigator,
                    observers: [widget.controller._observer],
                    onDidRemovePage: (page) {
                      if (!widget
                          .controller
                          ._navigator
                          .currentState!
                          .widget
                          .pages
                          .contains(page)) {
                        return;
                      }
                      if (page is! _SplitWorkspaceRoutePage) return;
                      if (page.key == _placeholderKey) return;
                      widget.onRemoved(page.id);
                    },
                    pages: [
                      _SplitWorkspaceRoutePage(
                        key: _placeholderKey,
                        id: _placeholderKey,
                        headerTitle: split
                            ? widget.landingTitle
                            : widget.catalogTitle,
                        backdrop: widget.backdrop,
                        child: split
                            ? _RetainedLanding(
                                child: pages.isEmpty ? widget.landing : null,
                              )
                            : widget.catalog,
                      ),
                      for (final page in pages)
                        _SplitWorkspaceRoutePage(
                          key: ValueKey(page.id),
                          id: page.id,
                          headerTitle: _joinTitles(
                            pages
                                .take(pages.indexOf(page) + 1)
                                .map((item) => item.title),
                          ),
                          backdrop: widget.backdrop,
                          child: PagePresentationScope(
                            previousTitle: !split
                                ? null
                                : pages.indexOf(page) == 0
                                ? widget.landingTitle
                                : _joinTitles(
                                    pages
                                        .take(pages.indexOf(page))
                                        .map((item) => item.title),
                                  ),
                            previousHasBack: pages.indexOf(page) > 0,
                            transitionTitle: _joinTitles(
                              pages
                                  .take(pages.indexOf(page) + 1)
                                  .map((item) => item.title),
                            ),
                            onTitleSelect: split
                                ? (index) => unawaited(
                                    widget.controller._popTo(index + 1),
                                  )
                                : null,
                            child: CappedBodyScope(
                              maxWidth: split
                                  ? widget.maxBodyWidth
                                  : double.infinity,
                              child: page.child,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        final bar = navigation?.held == true
            ? navigation!.navigation
            : const SizedBox.shrink();
        return ViewScope(
          size: parent?.size ?? constraints.biggest,
          isMobile: !split,
          windowControls: parent?.windowControls ?? Size.zero,
          child: !split || navigation == null
              ? workspace
              : navigation.floating
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    workspace,
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      child: bar,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: workspace),
                    bar,
                  ],
                ),
        );
      },
    );
  }
}

/// Keeps the landing under the first page while that page fades in, then
/// empties, so a later replacement never uncovers it.
class _RetainedLanding extends StatefulWidget {
  const _RetainedLanding({required this.child});

  final Widget? child;

  @override
  State<_RetainedLanding> createState() => _RetainedLandingState();
}

class _RetainedLandingState extends State<_RetainedLanding> {
  Widget? _shown;
  Animation<double>? _cover;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_RetainedLanding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    _cover?.removeStatusListener(_onCover);
    _cover = null;
    if (widget.child case final child?) {
      _shown = child;
      return;
    }
    final cover = ModalRoute.of(context)?.secondaryAnimation;
    if (cover == null || cover.isCompleted) {
      _shown = null;
    } else {
      _cover = cover..addStatusListener(_onCover);
    }
  }

  void _onCover(AnimationStatus status) {
    if (status.isCompleted) setState(_sync);
  }

  @override
  void dispose() {
    _cover?.removeStatusListener(_onCover);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _shown ?? const SizedBox.expand();
}

class _SplitWorkspaceRoutePage extends Page<void> {
  const _SplitWorkspaceRoutePage({
    super.key,
    required this.id,
    required this.headerTitle,
    required this.child,
    required this.backdrop,
  });

  final Object id;
  final String headerTitle;
  final Widget child;
  final Widget backdrop;

  @override
  Route<void> createRoute(BuildContext context) {
    final previous = context
        .findAncestorStateOfType<_SplitWorkspaceState>()
        ?.widget
        .controller
        ._observer
        .top
        ?.settings;
    return _SplitWorkspacePageRoute(
      settings: this,
      backdrop: backdrop,
      previousTitle: previous is _SplitWorkspaceRoutePage
          ? previous.headerTitle
          : null,
      previousHasBack:
          previous is _SplitWorkspaceRoutePage &&
          previous.key != _placeholderKey,
    );
  }
}

abstract class _SplitWorkspaceRoute<T> extends PageRoute<T>
    with DragBackRouteMixin<T>, DeferredPushRouteMixin<T> {
  _SplitWorkspaceRoute({super.settings, required this.backdrop});

  final Widget backdrop;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => SlideOverPageTransition.duration;

  @override
  Duration get reverseTransitionDuration =>
      SlideOverPageTransition.reverseDuration;

  // A desktop pan in the split layout selects text and resizes panes.
  @override
  bool get popGestureEnabled =>
      (!isDesktopPlatform ||
          navigator?.context
                  .findAncestorStateOfType<_SplitWorkspaceState>()
                  ?._split ==
              false) &&
      super.popGestureEnabled;

  bool get coversBelow => true;

  Widget buildContent(BuildContext context, Animation<double> animation);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => dragBackDetector(
    SlideOverPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      dragged: isDragBackActive,
      uncoveredByGesture: navigator!.userGestureInProgress,
      child: child,
    ),
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final content = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: KeyboardInsetHold(
        child: PageViewport.inherit(
          context,
          child: coversBelow
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    _SplitWorkspaceBackdrop(backdrop: backdrop),
                    buildContent(context, animation),
                  ],
                )
              : buildContent(context, animation),
        ),
      ),
    );
    if (!coversBelow) return content;
    // Keeps the inset wrapper in both layouts so promoting the pane does not
    // remount the page to gain or lose it; it is a no-op when not mobile.
    final mobile = ViewScope.isMobileOf(context);
    final padding = MediaQuery.paddingOf(context);
    final navigation = mobile ? NavigationDockScope.maybeOf(context) : null;
    return BottomInsetScope(
      inset: 0,
      child: Builder(
        builder: (context) {
          final data = MediaQuery.of(context);
          return MediaQuery(
            data: !mobile
                ? data
                : data.copyWith(
                    padding: padding.copyWith(
                      bottom: navigation?.bottomPadding ?? padding.bottom,
                    ),
                  ),
            child: content,
          );
        },
      ),
    );
  }
}

class _SplitWorkspacePageRoute extends _SplitWorkspaceRoute<void> {
  _SplitWorkspacePageRoute({
    required super.settings,
    required super.backdrop,
    required this.previousTitle,
    required this.previousHasBack,
  });

  final String? previousTitle;
  final bool previousHasBack;

  @override
  bool get coversBelow => !_SplitWorkspaceRouteObserver.isPlaceholder(this);

  @override
  Widget buildContent(BuildContext context, Animation<double> animation) {
    final child = (settings as _SplitWorkspaceRoutePage).child;
    if (!coversBelow || child is! PagePresentationScope) return child;
    // Always wraps, even when there is no previous title to animate, so
    // promoting the pane does not remount the page to gain that wrapper.
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final returning = animation.status == AnimationStatus.reverse;
        return PagePresentationScope(
          title: child.title,
          onTitleSelect: child.onTitleSelect,
          transitionTitle: child.transitionTitle,
          previousTitle: returning
              ? child.previousTitle
              : previousTitle ?? child.previousTitle,
          previousHasBack: returning ? child.previousHasBack : previousHasBack,
          child: child.child,
        );
      },
    );
  }
}

/// A page a workspace page pushes itself, presented as one more step of its
/// path.
class _SplitWorkspaceDetailRoute<T> extends _SplitWorkspaceRoute<T> {
  _SplitWorkspaceDetailRoute({
    required this.host,
    required this.parent,
    required this.parentHasBack,
    required this.page,
    required super.backdrop,
  });

  final SplitWorkspaceController host;
  final String? parent;
  final bool parentHasBack;
  final Widget page;

  /// The index of this page's own title in its path header.
  int get depth => parent?.split(' › ').length ?? 0;

  @override
  Widget buildContent(BuildContext context, Animation<double> animation) {
    final split = !ViewScope.isMobileOf(context);
    return PagePresentationScope(
      previousTitle: split ? parent : null,
      previousHasBack: parentHasBack,
      onTitleSelect: split ? host._selectPathSegment : null,
      child: CappedBodyScope(
        maxWidth: split
            ? host._host?.widget.maxBodyWidth ?? 840
            : double.infinity,
        child: PageNavigationScope(
          canOpen: (_) => false,
          open: (_) {},
          push: host.pushDetail,
          child: page,
        ),
      ),
    );
  }
}

/// Covers the pages beneath with the workspace backdrop, which holds still as
/// the page slides in or back, or changes tabs.
class _SplitWorkspaceBackdrop extends StatelessWidget {
  const _SplitWorkspaceBackdrop({required this.backdrop});

  final Widget backdrop;

  @override
  Widget build(BuildContext context) =>
      TabContentMotion.wrap(context, backdrop);
}

class _SplitWorkspaceRouteObserver extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];

  Route<dynamic>? get top => _routes.lastOrNull;

  Iterable<Route<dynamic>> get pages =>
      _routes.where((route) => route.settings is Page && !isPlaceholder(route));

  static bool isPlaceholder(Route<dynamic>? route) =>
      route?.settings is Page &&
      (route!.settings as Page).key == _placeholderKey;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) _routes[index] = newRoute;
  }
}
