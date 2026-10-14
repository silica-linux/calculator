// The programmer mode panel under the display (ca06-programmer): a divider at y 132, three
// segmented controls 24 pt high at y 137 (encoding 150 wide at x 10, the binary switch 126 at
// x 198, the base 117 at x 361 with the chosen base in orange) and the bit editor: two rows of
// 32 bits in groups of four (groups at a 61.7 pt pitch from x 12, digits baselines 189 and
// 222, `#9e9e9e`), with the bit positions under them (63, 47, 32 / 31, 15, 0).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'engine/programmer.dart';
import 'metrics.dart';

TextStyle _style(double size, Color color) => TextStyle(
  fontFamily: uiFontFamily,
  package: 'silica_ui',
  fontSize: size,
  color: color,
  height: 1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.width,
    required this.labels,
    required this.chosen,
    this.chosenColor = segmentChosen,
    required this.onTap,
    required this.keyPrefix,
  });

  final double width;
  final List<String> labels;

  /// The chosen segment (null: none shown as chosen).
  final int? chosen;

  /// Orange, gray in an inactive window (CA-02).
  final Color chosenColor;
  final ValueChanged<int> onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final each = width / labels.length;
    return Container(
      width: width,
      height: segmentHeight,
      decoration: BoxDecoration(
        color: segmentFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 12,
                color: chosen == i || chosen == i - 1
                    ? null
                    : const Color(0xFF5A5A5B),
              ),
            GestureDetector(
              key: ValueKey('$keyPrefix ${labels[i]}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Container(
                width: each - (i > 0 ? 1 : 0),
                height: segmentHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chosen == i ? chosenColor : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labels[i],
                  style: _style(12.5, const Color(0xFFFFFFFF)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProgrammerPanel extends StatelessWidget {
  const ProgrammerPanel({
    super.key,
    required this.calc,
    required this.showBinaryLabel,
    required this.hideBinaryLabel,
    this.active = true,
  });

  final ProgrammerCalculator calc;
  final String showBinaryLabel;
  final String hideBinaryLabel;

  /// The window is active.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final value = calc.current;
    final bits = value.toRadixString(2).padLeft(64, '0');
    Widget row(int high, List<int> labels) => Stack(
      children: [
        for (var g = 0; g < 8; g++)
          Positioned(
            left: 12 + g * 61.71,
            top: 0,
            child: Row(
              children: [
                for (var b = 0; b < 4; b++)
                  GestureDetector(
                    key: ValueKey('bit ${high - g * 4 - b}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => calc.toggleBit(high - g * 4 - b),
                    child: SizedBox(
                      width: 8.25,
                      height: 15,
                      child: Baseline(
                        baseline: 12,
                        baselineType: TextBaseline.alphabetic,
                        child: Text(
                          bits[63 - (high - g * 4 - b)],
                          textAlign: TextAlign.center,
                          style: _style(12.5, bitText),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        for (final (i, label) in labels.indexed)
          Positioned(
            left: i == 0 ? 11 : (i == 1 ? 257 : null),
            right: i == 2 ? 488 - 476 : null,
            top: 14,
            child: Text('$label', style: _style(10, bitLabel)),
          ),
      ],
    );
    return Stack(
      children: [
        Positioned(
          left: 10,
          right: 10,
          top: programmerDividerY,
          height: 1,
          child: const ColoredBox(color: programmerDivider),
        ),
        Positioned(
          left: 10,
          top: segmentTop,
          child: _Segmented(
            keyPrefix: 'encoding',
            width: 150,
            labels: const ['ASCII', 'Unicode'],
            chosen: null,
            onTap: (i) =>
                calc.setEncoding(i == 0 ? Encoding.ascii : Encoding.unicode),
          ),
        ),
        Positioned(
          left: 198,
          top: segmentTop,
          child: _Segmented(
            keyPrefix: 'binary',
            width: 126,
            labels: [calc.showBinary ? hideBinaryLabel : showBinaryLabel],
            chosen: null,
            onTap: (_) => calc.toggleBinary(),
          ),
        ),
        Positioned(
          left: 361,
          top: segmentTop,
          child: _Segmented(
            keyPrefix: 'base',
            chosenColor: active ? segmentChosen : segmentChosenInactive,
            width: 117,
            labels: const ['8', '10', '16'],
            chosen: const [8, 10, 16].indexOf(calc.base),
            onTap: (i) => calc.setBase(const [8, 10, 16][i]),
          ),
        ),
        if (calc.showBinary) ...[
          Positioned(
            left: 0,
            right: 0,
            top: 177,
            height: 30,
            child: row(63, const [63, 47, 32]),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 210,
            height: 30,
            child: row(31, const [31, 15, 0]),
          ),
        ],
      ],
    );
  }
}
