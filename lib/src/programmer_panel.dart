// The programmer mode panel under the display (kit `Apps/Calculator/Programmer`): a row of
// 24 pt controls at y 128 (the character view selector at x 16, the binary switch beside it,
// the base selector ending 12 pt from the right edge) and the bit editor, a 496 × 64 well at
// y 160 with two rows of 32 bits in groups of four (mono 12 / 16) and the index of the first
// bit of each row. Every bit is a toggle.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'engine/programmer.dart';
import 'metrics.dart';

/// The width of one mono character at 12 pt (JetBrains Mono: 0.6 em).
const double _bitWidth = 7.2;

/// The x of the bit rows inside the editor and of the bit index labels (kit `Bits high`, `Bit 63`).
const double _bitsLeft = 16;
const double _indexLeft = 312;

class ProgrammerPanel extends StatelessWidget {
  const ProgrammerPanel({
    super.key,
    required this.calc,
    required this.showBinaryLabel,
    required this.hideBinaryLabel,
  });

  final ProgrammerCalculator calc;
  final String showBinaryLabel;
  final String hideBinaryLabel;

  static const List<int> bases = [8, 10, 16];

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final bits = calc.current.toRadixString(2).padLeft(64, '0');
    Widget row(int high) {
      final style = AmalfiType.mono(color: colors.textPrimary);
      return SizedBox(
        height: 16,
        child: Row(
          children: [
            for (var g = 0; g < 8; g++) ...[
              if (g > 0) const SizedBox(width: _bitWidth),
              for (var b = 0; b < 4; b++)
                GestureDetector(
                  key: ValueKey('bit ${high - g * 4 - b}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => calc.toggleBit(high - g * 4 - b),
                  child: SizedBox(
                    width: _bitWidth,
                    height: 16,
                    child: Text(
                      bits[63 - (high - g * 4 - b)],
                      style: style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    }

    Widget index(int n) =>
        Text('$n', style: AmalfiType.caption(color: colors.textTertiary));

    return Stack(
      children: [
        Positioned(
          left: 16,
          top: selectorTop,
          child: AmalfiSegmentedControl(
            key: const ValueKey('encoding'),
            size: AmalfiControlSize.small,
            segments: const [
              AmalfiSegment.text('ASCII'),
              AmalfiSegment.text('Unicode'),
            ],
            selected: {calc.encoding.index},
            onChanged: (s) => calc.setEncoding(Encoding.values[s.first]),
          ),
        ),
        Positioned(
          left: 148,
          top: selectorTop,
          child: AmalfiPushButton(
            key: const ValueKey('binary'),
            size: AmalfiControlSize.small,
            label: calc.showBinary ? hideBinaryLabel : showBinaryLabel,
            onPressed: calc.toggleBinary,
          ),
        ),
        Positioned(
          right: 12,
          top: selectorTop,
          child: AmalfiSegmentedControl(
            key: const ValueKey('base'),
            size: AmalfiControlSize.small,
            segments: const [
              AmalfiSegment.text('8'),
              AmalfiSegment.text('10'),
              AmalfiSegment.text('16'),
            ],
            selected: {bases.indexOf(calc.base)},
            onChanged: (s) => calc.setBase(bases[s.first]),
          ),
        ),
        if (calc.showBinary)
          Positioned(
            key: const ValueKey('bit editor'),
            left: 16,
            top: bitEditorTop,
            width: 496,
            height: bitEditorHeight,
            child: DecoratedBox(
              decoration: AmalfiShapeDecoration(
                color: colors.calculator.bitEditor,
                shape: AmalfiSmoothBorder(radius: bitEditorRadius),
              ),
              child: Stack(
                children: [
                  Positioned(left: _bitsLeft, top: 8, child: row(63)),
                  Positioned(left: _bitsLeft, top: 32, child: row(31)),
                  Positioned(left: _indexLeft, top: 10, child: index(63)),
                  Positioned(left: _indexLeft, top: 34, child: index(31)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
