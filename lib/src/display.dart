// The display (kit `Display/Primary`: Inter Bold 34 / 40, right-aligned in a 40 pt box at y 68,
// 16 pt from the window edges). After "=" the expression sits on a line above it in
// `Display Secondary`. A long entry shrinks to 22 pt and then scrolls out to the left behind a
// 13 pt fade (calculator.md › Display).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'metrics.dart';

const double _smallSize = 22;
const double _expressionSize = 15;

TextStyle _tabular(TextStyle style) =>
    style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

double _width(String text, TextStyle style) => (TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout()).width;

/// One right-aligned line in a box of [height], shrinking from [style] to [small] and then
/// fading out on the left when it does not fit. [suffix] is drawn after it, smaller and lower
/// (the base of the programmer mode).
class DisplayLine extends StatelessWidget {
  const DisplayLine({
    super.key,
    required this.text,
    required this.style,
    required this.height,
    this.small,
    this.suffix,
  });

  final String text;
  final TextStyle style;
  final double height;
  final double? small;
  final String? suffix;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = style.fontSize ?? 34;
      final suffixStyle = style.copyWith(fontSize: size * 0.42);
      final room =
          box.maxWidth -
          (suffix == null ? 0 : _width(suffix!, suffixStyle) + 1);
      var shown = style;
      if (_width(text, shown) > room && small != null) {
        shown = style.copyWith(fontSize: small);
      }
      final overflow = _width(text, shown) > room;
      Widget line = Text(text, style: shown, maxLines: 1, softWrap: false);
      if (overflow) {
        line = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            colors: const [Color(0x00000000), Color(0xFF000000)],
            stops: [0, 13 / rect.width],
          ).createShader(rect),
          child: ClipRect(
            child: SizedBox(
              width: room,
              child: OverflowBox(
                alignment: Alignment.centerRight,
                maxWidth: double.infinity,
                child: line,
              ),
            ),
          ),
        );
      }
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              line,
              if (suffix != null) Text(suffix!, style: suffixStyle),
            ],
          ),
        ),
      );
    },
  );
}

/// The two lines of the display and an indicator on the left (Rad, the programmer character),
/// in a box from the window's top: the main line at y 68, the expression above it.
class Display extends StatelessWidget {
  const Display({
    super.key,
    required this.main,
    this.upper,
    this.indicator,
    this.suffix,
  });

  final String main;
  final String? upper;
  final String? indicator;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final secondary = colors.calculator.displaySecondary;
    final mainStyle = _tabular(AmalfiType.display(color: colors.textPrimary));
    return Stack(
      children: [
        if (upper != null && upper!.isNotEmpty)
          Positioned(
            key: const ValueKey('expression line'),
            left: 0,
            right: 0,
            top: expressionTop,
            height: expressionHeight,
            child: DisplayLine(
              text: upper!,
              style: _tabular(
                AmalfiType.display(color: secondary).copyWith(
                  fontSize: _expressionSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
              height: expressionHeight,
            ),
          ),
        Positioned(
          key: const ValueKey('main line'),
          left: 0,
          right: 0,
          top: displayTop,
          height: displayHeight,
          child: DisplayLine(
            text: main,
            style: mainStyle,
            small: _smallSize,
            height: displayHeight,
            suffix: suffix,
          ),
        ),
        if (indicator != null)
          Positioned(
            left: 0,
            top: displayTop,
            height: displayHeight,
            child: Center(
              child: Text(
                indicator!,
                style: AmalfiType.caption(color: secondary),
              ),
            ),
          ),
      ],
    );
  }
}
