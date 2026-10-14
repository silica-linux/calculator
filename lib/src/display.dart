// The display (calculator.md › Display): the main line right-aligned 12 pt from the window
// edge, baseline at y 119, 24 pt cap height; after "=" the expression on a line above
// (baseline 81, 17 pt cap height, `#9e9e9e`). A long entry shrinks to 17 pt and then scrolls
// out to the left behind a 13 pt fade.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'metrics.dart';

TextStyle displayStyle(double size, Color color) => TextStyle(
  fontFamily: uiFontFamily,
  package: 'silica_ui',
  fontSize: size,
  color: color,
  height: 1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

double _width(String text, TextStyle style) => (TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout()).width;

/// One line at `baseline`, right-aligned, shrinking from `size` to `small` and then fading out
/// on the left when it does not fit. `suffix` is drawn after it, smaller and lower (the base
/// of the programmer mode).
class DisplayLine extends StatelessWidget {
  const DisplayLine({
    super.key,
    required this.text,
    required this.baseline,
    required this.size,
    required this.color,
    this.small,
    this.suffix,
  });

  final String text;
  final double baseline;
  final double size;
  final double? small;
  final Color color;
  final String? suffix;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final suffixStyle = displayStyle(size * 0.42, color);
      final room =
          box.maxWidth -
          (suffix == null ? 0 : _width(suffix!, suffixStyle) + 1);
      var style = displayStyle(size, color);
      if (_width(text, style) > room && small != null) {
        style = displayStyle(small!, color);
      }
      final overflow = _width(text, style) > room;
      Widget line = Text(text, style: style, maxLines: 1, softWrap: false);
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
        height: baseline + size * 0.35,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Baseline(
                baseline: baseline,
                baselineType: TextBaseline.alphabetic,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    line,
                    if (suffix != null)
                      Transform.translate(
                        offset: Offset(1, size * 0.12),
                        child: Text(suffix!, style: suffixStyle),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// The two lines of the display and an indicator on the left (Rad, the programmer character).
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
  Widget build(BuildContext context) => Stack(
    children: [
      if (upper != null && upper!.isNotEmpty)
        Positioned.fill(
          key: const ValueKey('expression line'),
          child: DisplayLine(
            text: upper!,
            baseline: upperBaseline,
            size: upperFontSize,
            color: displaySecondary,
          ),
        ),
      Positioned.fill(
        key: const ValueKey('main line'),
        child: DisplayLine(
          text: main,
          baseline: mainBaseline,
          size: mainFontSize,
          small: upperFontSize,
          color: displayText,
          suffix: suffix,
        ),
      ),
      if (indicator != null)
        Positioned(
          left: 0,
          top: 0,
          child: Baseline(
            baseline: mainBaseline,
            baselineType: TextBaseline.alphabetic,
            child: Text(indicator!, style: displayStyle(13, displaySecondary)),
          ),
        ),
    ],
  );
}
