// The keypads of the three modes, row by row (silica-reference CA-01).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'engine/calculator.dart';
import 'engine/expression.dart';
import 'engine/format.dart';
import 'engine/programmer.dart';
import 'glyphs.dart';
import 'metrics.dart';

class KeySpec {
  const KeySpec(
    this.id,
    this.role,
    this.label,
    this.action, {
    this.toggled = false,
    this.tooltip,
  });

  final String id;
  final KeyRole role;
  final Widget Function(Color color) label;
  final VoidCallback action;
  final bool toggled;
  final String? tooltip;
}

Widget Function(Color) _text(
  String s, {
  double size = 22,
  FontWeight weight = FontWeight.w600,
}) =>
    (color) => Text(
      s,
      style: TextStyle(
        fontFamily: uiFontFamily,
        package: 'silica_ui',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1,
        // Two-letter labels (AC, FF) are a little tighter than Inter SemiBold: 27 pt wide.
        letterSpacing: s.length > 1 ? -1.2 : 0,
      ),
    );

Widget Function(Color) _glyph(Glyph g) =>
    (color) => GlyphIcon(g, color: color);

Widget Function(Color) _label(KeyLabel l, {double size = 15}) =>
    (color) =>
        KeyLabelText(l, color: color, size: size, weight: FontWeight.w600);

/// Texts the keypads need from the localizations.
class KeyTexts {
  const KeyTexts({
    required this.clearAll,
    required this.clear,
    required this.secondTooltip,
  });
  final String clearAll;
  final String clear;
  final String secondTooltip;
}

/// The digits and operators shared by the basic and scientific keypads (the right four
/// columns).
List<List<KeySpec>> _decimalPad(
  DecimalCalculator c,
  NumberStyle style,
  KeyTexts t, {
  double digitSize = 22,
}) {
  KeySpec digit(String d) =>
      KeySpec(d, KeyRole.digit, _text(d, size: digitSize), () => c.digit(d));
  KeySpec op(String id, Glyph g, BinOp o) =>
      KeySpec(id, KeyRole.operator, _glyph(g), () => c.operator(o));
  return [
    [
      KeySpec(
        'backspace',
        KeyRole.function,
        _glyph(Glyph.backspace),
        c.backspace,
      ),
      KeySpec(
        'clear',
        KeyRole.function,
        _text(c.showsClear ? t.clear : t.clearAll, size: digitSize),
        c.clear,
      ),
      KeySpec(
        'percent',
        KeyRole.function,
        _text('%', size: digitSize),
        () => c.postfix(Postfix.percent),
      ),
      op('divide', Glyph.divide, BinOp.divide),
    ],
    [
      digit('7'),
      digit('8'),
      digit('9'),
      op('multiply', Glyph.multiply, BinOp.multiply),
    ],
    [
      digit('4'),
      digit('5'),
      digit('6'),
      op('subtract', Glyph.minus, BinOp.subtract),
    ],
    [digit('1'), digit('2'), digit('3'), op('add', Glyph.plus, BinOp.add)],
    [
      KeySpec('negate', KeyRole.digit, _glyph(Glyph.plusMinus), c.negate),
      digit('0'),
      KeySpec(
        'decimal',
        KeyRole.digit,
        _text(style.decimal, size: digitSize),
        c.decimalPoint,
      ),
      KeySpec('equals', KeyRole.operator, _glyph(Glyph.equals), c.equals),
    ],
  ];
}

List<List<KeySpec>> basicKeys(
  DecimalCalculator c,
  NumberStyle style,
  KeyTexts t,
) => _decimalPad(c, style, t);

List<List<KeySpec>> scientificKeys(
  DecimalCalculator c,
  NumberStyle style,
  KeyTexts t,
) {
  final second = c.second;
  KeySpec sci(String id, KeyLabel label, VoidCallback action) =>
      KeySpec(id, KeyRole.scientific, _label(label), action);
  KeySpec fn(String id, KeyLabel label, Func f) =>
      sci(id, label, () => c.function(f));
  final pad = _decimalPad(c, style, t);
  final left = <List<KeySpec>>[
    [
      sci('open', const KeyLabel('('), c.open),
      sci('close', const KeyLabel(')'), c.close),
      sci('mc', const KeyLabel('mc'), c.memoryClear),
      sci('m+', const KeyLabel('m+'), c.memoryAdd),
      sci('m-', const KeyLabel('m-'), c.memorySubtract),
      sci('mr', const KeyLabel('mr'), c.memoryRecall),
    ],
    [
      KeySpec(
        'second',
        KeyRole.scientific,
        _label(const KeyLabel('2', sup: 'nd')),
        c.toggleSecond,
        toggled: second,
        tooltip: t.secondTooltip,
      ),
      sci(
        'square',
        const KeyLabel('x', sup: '2'),
        () => c.postfix(Postfix.square),
      ),
      sci('cube', const KeyLabel('x', sup: '3'), () => c.postfix(Postfix.cube)),
      sci(
        'power',
        const KeyLabel('x', sup: 'y'),
        () => c.operator(BinOp.power),
      ),
      second
          ? sci(
              'power-reversed',
              const KeyLabel('y', sup: 'x'),
              () => c.operator(BinOp.powerReversed),
            )
          : fn('exp', const KeyLabel('e', sup: 'x'), Func.exp),
      second
          ? fn('two-power', const KeyLabel('2', sup: 'x'), Func.twoPow)
          : fn('ten-power', const KeyLabel('10', sup: 'x'), Func.tenPow),
    ],
    [
      fn(
        'reciprocal',
        const KeyLabel('⁄', pre: '1', sub: 'x'),
        Func.reciprocal,
      ),
      fn('sqrt', const KeyLabel('√x', pre: '2'), Func.sqrt),
      fn('cbrt', const KeyLabel('√x', pre: '3'), Func.cbrt),
      sci('root', const KeyLabel('√x', pre: 'y'), () => c.operator(BinOp.root)),
      second
          ? sci(
              'log-base',
              const KeyLabel('log', sub: 'y'),
              () => c.operator(BinOp.logBase),
            )
          : fn('ln', const KeyLabel('ln'), Func.ln),
      second
          ? fn('log2', const KeyLabel('log', sub: '2'), Func.log2)
          : fn('log10', const KeyLabel('log', sub: '10'), Func.log10),
    ],
    [
      sci(
        'factorial',
        const KeyLabel('x!'),
        () => c.postfix(Postfix.factorial),
      ),
      fn(
        'sin',
        KeyLabel('sin', sup: second ? '-1' : null),
        second ? Func.asin : Func.sin,
      ),
      fn(
        'cos',
        KeyLabel('cos', sup: second ? '-1' : null),
        second ? Func.acos : Func.cos,
      ),
      fn(
        'tan',
        KeyLabel('tan', sup: second ? '-1' : null),
        second ? Func.atan : Func.tan,
      ),
      sci('e', const KeyLabel('e'), () => c.constant(Constant.e)),
      sci('ee', const KeyLabel('EE'), c.exponent),
    ],
    [
      sci('rand', const KeyLabel('Rand'), c.randomNumber),
      fn(
        'sinh',
        KeyLabel('sinh', sup: second ? '-1' : null),
        second ? Func.asinh : Func.sinh,
      ),
      fn(
        'cosh',
        KeyLabel('cosh', sup: second ? '-1' : null),
        second ? Func.acosh : Func.cosh,
      ),
      fn(
        'tanh',
        KeyLabel('tanh', sup: second ? '-1' : null),
        second ? Func.atanh : Func.tanh,
      ),
      sci('pi', const KeyLabel('π'), () => c.constant(Constant.pi)),
      // Shows the unit the key switches to.
      sci(
        'angle',
        KeyLabel(c.angle == AngleUnit.degrees ? 'Rad' : 'Deg'),
        c.toggleAngle,
      ),
    ],
  ];
  return [
    for (var i = 0; i < 5; i++) [...left[i], ...pad[i]],
  ];
}

List<List<KeySpec>> programmerKeys(ProgrammerCalculator p, KeyTexts t) {
  KeySpec digit(String d) =>
      KeySpec('digit $d', KeyRole.digit, _text(d, size: 22), () => p.digits(d));
  KeySpec pr(String id, KeyLabel label, VoidCallback action) =>
      KeySpec(id, KeyRole.programmer, _label(label, size: 15), action);
  KeySpec binary(String id, KeyLabel label, ProgOp op) =>
      pr(id, label, () => p.operator(op));
  KeySpec unary(String id, KeyLabel label, ProgUnary op) =>
      pr(id, label, () => p.unary(op));
  KeySpec op(String id, Glyph g, ProgOp o) =>
      KeySpec(id, KeyRole.operator, _glyph(g), () => p.operator(o));
  return [
    [
      KeySpec(
        'backspace',
        KeyRole.programmer,
        _glyph(Glyph.backspace),
        p.backspace,
      ),
      pr('open', const KeyLabel('('), p.open),
      pr('close', const KeyLabel(')'), p.close),
      digit('D'),
      digit('E'),
      digit('F'),
      KeySpec(
        'clear',
        KeyRole.function,
        _text(p.showsClear ? t.clear : t.clearAll, size: 22),
        p.clear,
      ),
    ],
    [
      binary('and', const KeyLabel('AND'), ProgOp.and),
      binary('or', const KeyLabel('OR'), ProgOp.or),
      binary('xor', const KeyLabel('XOR'), ProgOp.xor),
      digit('A'),
      digit('B'),
      digit('C'),
      op('divide', Glyph.divide, ProgOp.divide),
    ],
    [
      binary('nor', const KeyLabel('NOR'), ProgOp.nor),
      unary('shift-left-one', const KeyLabel('<<'), ProgUnary.shiftLeftOne),
      unary('shift-right-one', const KeyLabel('>>'), ProgUnary.shiftRightOne),
      digit('7'),
      digit('8'),
      digit('9'),
      op('multiply', Glyph.multiply, ProgOp.multiply),
    ],
    [
      unary('not', const KeyLabel('NOT'), ProgUnary.not),
      binary('shift-left', const KeyLabel('X<<Y'), ProgOp.shiftLeft),
      binary('shift-right', const KeyLabel('X>>Y'), ProgOp.shiftRight),
      digit('4'),
      digit('5'),
      digit('6'),
      op('subtract', Glyph.minus, ProgOp.subtract),
    ],
    [
      unary('negate', const KeyLabel('NEG'), ProgUnary.negate),
      unary('rotate-left', const KeyLabel('RoL'), ProgUnary.rotateLeft),
      unary('rotate-right', const KeyLabel('RoR'), ProgUnary.rotateRight),
      digit('1'),
      digit('2'),
      digit('3'),
      op('add', Glyph.plus, ProgOp.add),
    ],
    [
      binary('mod', const KeyLabel('mod'), ProgOp.modulo),
      unary('flip8', const KeyLabel('flip', sub: '8'), ProgUnary.flip8),
      unary('flip16', const KeyLabel('flip', sub: '16'), ProgUnary.flip16),
      KeySpec(
        'digits FF',
        KeyRole.digit,
        _text('FF', size: 22),
        () => p.digits('FF'),
      ),
      digit('0'),
      KeySpec(
        'digits 00',
        KeyRole.digit,
        _text('00', size: 22),
        () => p.digits('00'),
      ),
      KeySpec('equals', KeyRole.operator, _glyph(Glyph.equals), p.equals),
    ],
  ];
}
