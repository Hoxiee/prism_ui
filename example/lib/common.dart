import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart';
import 'package:prism_ui/prism_ui.dart';

/// A scrolling page body with a readable maximum width.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: children,
          ),
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({super.key, required this.title, this.caption, required this.child});

  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(title, style: AppTextStyle.headline.of(context)),
        if (caption != null) Note(caption!),
        child,
      ],
    );
  }
}

class Note extends StatelessWidget {
  const Note(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyle.footnote
          .of(context)
          .copyWith(color: context.colorScheme.onSurfaceVariant),
    );
  }
}

/// A rounded raised panel that frames a demo.
class Panel extends StatelessWidget {
  const Panel({super.key, this.padding = EdgeInsets.zero, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Surface(
      color: context.raisedSurfaceLevel.colorOf(scheme),
      shape: AppShape.all(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class Controls extends StatelessWidget {
  const Controls({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class LabeledSwitch extends StatelessWidget {
  const LabeledSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Switch(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }
}

class GalleryPage {
  const GalleryPage(this.id, this.title, this.glyph, this.builder);

  final String id;
  final String title;
  final Glyph glyph;
  final WidgetBuilder builder;
}
