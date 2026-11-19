import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../common.dart';

class MotionPage extends StatefulWidget {
  const MotionPage({super.key});

  @override
  State<MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends State<MotionPage> with TickerProviderStateMixin {
  static final _spring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 500),
    bounce: 0.3,
  );
  static const _tabs = ['Alpha', 'Beta', 'Gamma'];

  late final _navSpring = NavSpring(this, 0);
  late final _curve = AnimationController(
    vsync: this,
    duration: slideTabDuration,
  );
  late final _tabController = AnimationController(vsync: this);
  late final _slots = NavSlots<int>(vsync: this, spring: _spring)
    ..seed([1, 2, 3]);
  final _plan = TabMotionPlan<int>();
  var _right = false;
  var _tab = 0;
  var _page = 0;
  var _nextSlot = 4;
  var _revealed = true;
  var _entries = [0, 1, 2];
  var _nextEntry = 3;

  @override
  void initState() {
    super.initState();
    _tabController.addStatusListener((status) {
      if (status.isCompleted) _plan.clear();
    });
  }

  @override
  void dispose() {
    _navSpring.dispose();
    _curve.dispose();
    _tabController.dispose();
    _slots.dispose();
    super.dispose();
  }

  void _toggleSpring() {
    _right = !_right;
    _navSpring.springTo(_right ? 1 : 0, _spring);
  }

  void _selectTab(int next) {
    if (next == _tab) return;
    _plan.retarget(
      next,
      current: _tab,
      value: _tabController.value,
      forward: next > _tab,
      fade: false,
    );
    setState(() => _tab = next);
    _tabController.duration = _plan.duration;
    _tabController.forward(from: 0);
  }

  Widget _track({required Widget Function(double t) knob}) {
    return Panel(
      padding: const EdgeInsets.all(12),
      child: SizedBox(height: 48, child: knob(0)),
    );
  }

  Widget _knob(Color color) => Container(
    width: 48,
    height: 48,
    decoration: ShapeDecoration(color: color, shape: AppShape.all(14)),
  );

  Widget _springDemo(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Controls(
          children: [
            FilledButton(
              key: const ValueKey('motion-spring'),
              onPressed: _toggleSpring,
              child: const Text('Replay NavSpring'),
            ),
          ],
        ),
        _track(
          knob: (_) => LayoutBuilder(
            builder: (context, box) => AnimatedBuilder(
              animation: _navSpring,
              builder: (context, _) => Align(
                alignment: Alignment(_navSpring.value * 2 - 1, 0),
                child: _knob(color),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _curveDemo(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Controls(
          children: [
            FilledButton(
              key: const ValueKey('motion-curve'),
              onPressed: () => _curve.forward(from: 0),
              child: const Text('Replay slideTabCurve'),
            ),
          ],
        ),
        _track(
          knob: (_) => AnimatedBuilder(
            animation: _curve,
            builder: (context, _) => Align(
              alignment: Alignment(
                slideTabCurve.transform(_curve.value) * 2 - 1,
                0,
              ),
              child: _knob(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabDemo() {
    final scheme = context.colorScheme;
    Widget page(int key) {
      final colors = [
        scheme.primaryContainer,
        scheme.secondaryContainer,
        scheme.tertiaryContainer,
      ];
      return Container(
        decoration: ShapeDecoration(
          color: colors[key],
          shape: AppShape.all(16),
        ),
        alignment: Alignment.center,
        child: Text(_tabs[key], style: AppTextStyle.title2.of(context)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Controls(
          children: [
            for (final (i, name) in _tabs.indexed)
              TextButton(
                key: ValueKey('motion-tab-$i'),
                onPressed: () => _selectTab(i),
                child: Text(name),
              ),
          ],
        ),
        Panel(
          child: SizedBox(
            height: 140,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final keys = _plan.isActive ? {..._plan.keys, _tab} : {_tab};
                  return Stack(
                    children: [
                      for (final key in keys)
                        Positioned.fill(
                          child: TabMotionTransition(
                            animation: _tabController,
                            axis: Axis.horizontal,
                            frame: () => _plan.frameOf(
                              key,
                              current: _tab,
                              value: _tabController.value,
                            ),
                            child: page(key),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _swipeDemo() {
    return PageSwipe(
      enabled: true,
      onSwipe: (forward) => setState(
        () => _page = (_page + (forward ? 1 : -1)).clamp(0, _tabs.length - 1),
      ),
      child: Panel(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Page ${_page + 1} of ${_tabs.length}: swipe sideways',
            style: AppTextStyle.headline.of(context),
          ),
        ),
      ),
    );
  }

  Widget _slotsDemo(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Controls(
          children: [
            FilledButton(
              key: const ValueKey('motion-slot-add'),
              onPressed: () => _slots.sync([
                ..._slots.slots.where((s) => !s.leaving).map((s) => s.key),
                _nextSlot++,
              ]),
              child: const Text('Add slot'),
            ),
            FilledButton(
              key: const ValueKey('motion-slot-remove'),
              onPressed: () {
                final live = [
                  ..._slots.slots.where((s) => !s.leaving).map((s) => s.key),
                ];
                if (live.isNotEmpty) {
                  _slots.sync(live..removeAt(live.length ~/ 2));
                }
              },
              child: const Text('Remove middle'),
            ),
          ],
        ),
        Panel(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 56,
            child: ListenableBuilder(
              listenable: _slots,
              builder: (context, _) => Row(
                children: [
                  for (final slot in _slots.slots)
                    Flexible(
                      flex: (slot.weight.value * 1000).round().clamp(1, 1000),
                      child: Opacity(
                        opacity: slot.weight.value.clamp(0.0, 1.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: color,
                            shape: AppShape.all(14),
                          ),
                          child: Text('${slot.key}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _entriesDemo() {
    Widget entry(int id) => Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text('Entry ${id + 1}'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Controls(
          children: [
            FilledButton(
              key: const ValueKey('motion-entry-add'),
              onPressed: () =>
                  setState(() => _entries = [..._entries, _nextEntry++]),
              child: const Text('Add entry'),
            ),
            FilledButton(
              onPressed: () => setState(() {
                if (_entries.isNotEmpty) {
                  _entries = [..._entries]..removeAt(_entries.length ~/ 2);
                }
              }),
              child: const Text('Remove middle'),
            ),
            FilledButton(
              key: const ValueKey('motion-reveal'),
              onPressed: () => setState(() => _revealed = !_revealed),
              child: Text(_revealed ? 'Hide reveal' : 'Show reveal'),
            ),
          ],
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedEntries(children: [for (final id in _entries) entry(id)]),
              AnimatedReveal(
                visible: _revealed,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('AnimatedReveal child'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.primary;
    return PageBody(
      children: [
        Section(title: 'NavSpring (spring.dart)', child: _springDemo(color)),
        Section(title: 'SpringCurve (motion.dart)', child: _curveDemo(color)),
        Section(
          title: 'TabMotionPlan and TabMotionTransition',
          caption: 'Switch quickly: an interrupted slide restarts where drawn.',
          child: _tabDemo(),
        ),
        Section(title: 'PageSwipe', child: _swipeDemo()),
        Section(
          title: 'NavSlots',
          caption: 'Slots grow in and collapse out on NavSpring weights.',
          child: _slotsDemo(color),
        ),
        Section(
          title: 'AnimatedEntries and AnimatedReveal',
          child: _entriesDemo(),
        ),
      ],
    );
  }
}
