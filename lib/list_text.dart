import 'package:flutter/widgets.dart';
import 'package:prism_ui/measure.dart';
import 'package:prism_ui/metrics.dart';
import 'package:prism_ui/typography.dart';

extension ListTextContext on BuildContext {
  /// The least a row stands, so one that drops its padding still stands as
  /// tall as a padded line of its title.
  double get listLineRowHeight => listRowExtent(
    titleHeight: MeasureScope.of(this).textHeight(AppTextStyle.body),
  );
}
