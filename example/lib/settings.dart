import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

const seedChoices = <Color>[
  Color(0xFF6750A4),
  Color(0xFF0B6BCB),
  Color(0xFF1B8A5A),
  Color(0xFFD97706),
  Color(0xFFC62E65),
  Color(0xFF455A64),
];

class GallerySettings extends ChangeNotifier {
  GallerySettings({
    this._dark = false,
    this._seed = const Color(0xFF6750A4),
    this._contrast = ColorContrast.standard,
    this._page = 0,
  });

  bool _dark;
  Color _seed;
  ColorContrast _contrast;
  int _page;
  bool sidebarExpanded = true;

  bool get dark => _dark;
  Color get seed => _seed;
  ColorContrast get contrast => _contrast;
  int get page => _page;

  set dark(bool value) => _update(() => _dark = value);
  set seed(Color value) => _update(() => _seed = value);
  set contrast(ColorContrast value) => _update(() => _contrast = value);
  set page(int value) => _update(() => _page = value);

  void toggleSidebar() => _update(() => sidebarExpanded = !sidebarExpanded);

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

class SettingsScope extends InheritedNotifier<GallerySettings> {
  const SettingsScope({
    super.key,
    required GallerySettings settings,
    required super.child,
  }) : super(notifier: settings);

  static GallerySettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
