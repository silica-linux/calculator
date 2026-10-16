// Key faces: the operator and backspace glyph ids, the fallback backspace drawn in code when
// the Icon Kit symbol is not installed, and labels with a raised or lowered part (x², log₁₀,
// 2ⁿᵈ) built from two text sizes (kit `Key/Scientific`, Title 3).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

enum Glyph { divide, multiply, minus, plus, equals, plusMinus, backspace }

/// The backspace key drawn in code: a tag pointing left with an × inside.
class BackspacePainter extends CustomPainter {
  const BackspacePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(c.dx - 10, c.dy)
      ..lineTo(c.dx - 4.5, c.dy - 8)
      ..lineTo(c.dx + 7, c.dy - 8)
      ..arcToPoint(
        Offset(c.dx + 10, c.dy - 5),
        radius: const Radius.circular(3),
      )
      ..lineTo(c.dx + 10, c.dy + 5)
      ..arcToPoint(Offset(c.dx + 7, c.dy + 8), radius: const Radius.circular(3))
      ..lineTo(c.dx - 4.5, c.dy + 8)
      ..close();
    canvas
      ..drawPath(path, s)
      ..drawLine(c.translate(-1, -3.5), c.translate(6, 3.5), s)
      ..drawLine(c.translate(6, -3.5), c.translate(-1, 3.5), s);
  }

  @override
  bool shouldRepaint(BackspacePainter old) => old.color != color;
}

/// The fallback backspace glyph in a box of `size`.
class BackspaceIcon extends StatelessWidget {
  const BackspaceIcon({super.key, required this.color, this.size = 24});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: BackspacePainter(color));
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
    final style = AmalfiType.title3(color: color);
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
