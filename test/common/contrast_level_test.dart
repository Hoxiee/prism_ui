import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/color.dart';
import 'package:prism_ui/color_scheme.dart';
import 'package:prism_ui/hct/dynamic_color.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const seeds = [Color(0xFF3F51B5), Color(0xFFE91E63), Color(0xFF4CAF50)];
  const styles = [ColorStyle.vivid, ColorStyle.soft];

  ColorScheme build(Color s, Brightness b, ColorStyle st, ColorContrast c) =>
      seededColorScheme(seedColor: s, brightness: b, style: st, contrast: c);

  test('ContrastCurve interpolates between its anchors', () {
    const curve = ContrastCurve(1, 3, 5, 9);
    expect(curve.get(-1), 1);
    expect(curve.get(0), 3);
    expect(curve.get(0.25), 4);
    expect(curve.get(0.5), 5);
    expect(curve.get(1), 9);
  });

  for (final seed in seeds) {
    for (final brightness in Brightness.values) {
      for (final style in styles) {
        test(
          'contrast grows with level: ${seed.toARGB32()} $brightness $style',
          () {
            final schemes = [
              for (final c in ColorContrast.values)
                build(seed, brightness, style, c),
            ];
            double onSurface(ColorScheme s) => _ratio(s.onSurface, s.surface);
            double onPrimary(ColorScheme s) => _ratio(s.onPrimary, s.primary);
            double outline(ColorScheme s) => _ratio(s.outline, s.surface);
            for (final f in [onSurface, onPrimary, outline]) {
              final values = schemes.map(f).toList();
              for (var i = 1; i < values.length; i++) {
                expect(values[i], greaterThanOrEqualTo(values[i - 1] - 0.01));
              }
            }
            expect(onSurface(schemes.last), greaterThanOrEqualTo(7));
            expect(schemes.last.outline, isNot(equals(schemes.first.outline)));
          },
        );
      }
    }
  }
}
