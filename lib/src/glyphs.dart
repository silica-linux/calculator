// Key glyphs drawn in code: the operators are symbols, not text (calculator.md › Keys:
// ÷ 17 × 15, + 17 × 16, − 16 × 2, = 14 × 8, × 13 × 13, ⌫ 22 × 18), and labels with a raised
// or lowered part (x², log₁₀, 2ⁿᵈ) built from two text sizes.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

enum Glyph {
  divide,
  multiply,
  minus,
  plus,
  equals,
  backspace,
  plusMinus,
  sidebar,
  calculator,
}

class GlyphPainter extends CustomPainter {
  const GlyphPainter(this.glyph, this.color);
  final Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    final c = size.center(Offset.zero);
    switch (glyph) {
      case Glyph.divide:
        canvas
          ..drawLine(c.translate(-7.5, 0), c.translate(7.5, 0), stroke)
          ..drawCircle(c.translate(0, -5.5), 1.6, fill)
          ..drawCircle(c.translate(0, 5.5), 1.6, fill);
      case Glyph.multiply:
        canvas
          ..drawLine(c.translate(-5.5, -5.5), c.translate(5.5, 5.5), stroke)
          ..drawLine(c.translate(5.5, -5.5), c.translate(-5.5, 5.5), stroke);
      case Glyph.minus:
        canvas.drawLine(c.translate(-8, 0), c.translate(8, 0), stroke);
      case Glyph.plus:
        canvas
          ..drawLine(c.translate(-8, 0), c.translate(8, 0), stroke)
          ..drawLine(c.translate(0, -7.5), c.translate(0, 7.5), stroke);
      case Glyph.equals:
        canvas
          ..drawLine(c.translate(-6, -3), c.translate(6, -3), stroke)
          ..drawLine(c.translate(-6, 3), c.translate(6, 3), stroke);
      case Glyph.backspace:
        // A tag pointing left, 22 × 18, with an × inside.
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
          ..arcToPoint(
            Offset(c.dx + 7, c.dy + 8),
            radius: const Radius.circular(3),
          )
          ..lineTo(c.dx - 4.5, c.dy + 8)
          ..close();
        canvas
          ..drawPath(path, s)
          ..drawLine(c.translate(-1, -3.5), c.translate(6, 3.5), s)
          ..drawLine(c.translate(6, -3.5), c.translate(-1, 3.5), s);
      case Glyph.plusMinus:
        // A small + up left, a slash, a small − down right.
        final s = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(c.translate(-9, -5), c.translate(-3, -5), s)
          ..drawLine(c.translate(-6, -8), c.translate(-6, -2), s)
          ..drawLine(c.translate(3.5, -8), c.translate(-3.5, 8), s)
          ..drawLine(c.translate(3, 5), c.translate(9, 5), s);
      case Glyph.sidebar:
        final s = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final r = Rect.fromCenter(center: c, width: 18, height: 14);
        canvas
          ..drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), s)
          ..drawRect(
            Rect.fromLTWH(r.left + 1.5, r.top + 1.5, 5, r.height - 3),
            fill,
          );
      case Glyph.calculator:
        final s = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final r = Rect.fromCenter(center: c, width: 13, height: 17);
        canvas
          ..drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2.5)), s)
          ..drawRect(
            Rect.fromLTWH(r.left + 2.5, r.top + 2.5, r.width - 5, 3.5),
            fill,
          );
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            canvas.drawRect(
              Rect.fromLTWH(
                r.left + 2.5 + col * 3,
                r.top + 8 + row * 2.6,
                1.8,
                1.6,
              ),
              fill,
            );
          }
        }
    }
  }

  @override
  bool shouldRepaint(GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}

/// A drawn glyph in a box of `size`.
class GlyphIcon extends StatelessWidget {
  const GlyphIcon(this.glyph, {super.key, required this.color, this.size = 24});
  final Glyph glyph;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: GlyphPainter(glyph, color));
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
  const KeyLabelText(
    this.label, {
    super.key,
    required this.color,
    required this.size,
    this.weight = FontWeight.w400,
  });

  final KeyLabel label;
  final Color color;
  final double size;
  final FontWeight weight;

  TextStyle _style(double s) => TextStyle(
    fontFamily: uiFontFamily,
    package: 'silica_ui',
    fontSize: s,
    fontWeight: weight,
    color: color,
    height: 1,
  );

  @override
  Widget build(BuildContext context) {
    final small = math.max(9.0, size * 0.62);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label.pre != null)
          Transform.translate(
            offset: Offset(0, -size * 0.32),
            child: Text(label.pre!, style: _style(small)),
          ),
        Text(label.base, style: _style(size)),
        if (label.sup != null)
          Transform.translate(
            offset: Offset(0.5, -size * 0.34),
            child: Text(label.sup!, style: _style(small)),
          ),
        if (label.sub != null)
          Transform.translate(
            offset: Offset(0.5, size * 0.3),
            child: Text(label.sub!, style: _style(small)),
          ),
      ],
    );
  }
}
