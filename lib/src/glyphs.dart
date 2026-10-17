// Key faces: the symbol-key glyph ids (Silica Symbols) and labels with a raised or lowered part
// (x², log₁₀, 2ⁿᵈ) built from two text sizes (kit `Key/Scientific`, Inter Semibold 18).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

enum Glyph {
  divide,
  multiply,
  minus,
  plus,
  equals,
  plusMinus,
  percent,
  backspace,
}

/// A label with an optional raised part (`x²`, `2ⁿᵈ`), lowered part (`log₁₀`) and a part
/// before the base (`²√x`, `¹⁄ₓ`).
class KeyLabel {
  const KeyLabel(this.base, {this.sup, this.sub, this.pre});
  final String base;
  final String? sup;
  final String? sub;
  final String? pre;
}

class KeyLabelText extends StatelessWidget {
  const KeyLabelText(this.label, {super.key, required this.color});

  final KeyLabel label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Kit `Key/Scientific`: Inter Semibold 18.
    final style = AmalfiType.title3(
      color: color,
    ).copyWith(fontSize: 18, fontWeight: FontWeight.w600);
    final size = style.fontSize ?? 17;
    final small = style.copyWith(fontSize: size * 0.62, height: 1);
    final base = style.copyWith(height: 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label.pre != null)
          Transform.translate(
            offset: Offset(0, -size * 0.32),
            child: Text(label.pre!, style: small),
          ),
        Text(label.base, style: base),
        if (label.sup != null)
          Transform.translate(
            offset: Offset(0.5, -size * 0.34),
            child: Text(label.sup!, style: small),
          ),
        if (label.sub != null)
          Transform.translate(
            offset: Offset(0.5, size * 0.3),
            child: Text(label.sub!, style: small),
          ),
      ],
    );
  }
}
