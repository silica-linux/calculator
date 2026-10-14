// The programmer mode (calculator.md › Display, ca06-programmer): 64-bit integers shown in
// base 8, 10 or 16, binary operators with precedence, and immediate one-operand operations
// (NOT, NEG, shifts and rotations by one, byte flips) applied to the current number.

import 'package:flutter/foundation.dart';

import 'rational.dart';

final BigInt _mask = (BigInt.one << 64) - BigInt.one;

BigInt _wrap(BigInt v) => v & _mask;

/// Two-operand operators, in groups of increasing binding strength.
enum ProgOp {
  or('OR', 0),
  nor('NOR', 0),
  xor('XOR', 1),
  and('AND', 2),
  shiftLeft('<<', 3),
  shiftRight('>>', 3),
  add('+', 4),
  subtract('−', 4),
  multiply('×', 5),
  divide('÷', 5),
  modulo('mod', 5);

  const ProgOp(this.symbol, this.level);
  final String symbol;
  final int level;
}

/// One-operand operations, applied at once.
enum ProgUnary {
  not,
  negate,
  shiftLeftOne,
  shiftRightOne,
  rotateLeft,
  rotateRight,
  flip8,
  flip16,
}

enum Encoding { ascii, unicode }

BigInt applyBinary(ProgOp op, BigInt a, BigInt b) {
  switch (op) {
    case ProgOp.add:
      return _wrap(a + b);
    case ProgOp.subtract:
      return _wrap(a - b);
    case ProgOp.multiply:
      return _wrap(a * b);
    case ProgOp.divide:
      if (b == BigInt.zero) throw const CalcError('division by zero');
      return a ~/ b;
    case ProgOp.modulo:
      if (b == BigInt.zero) throw const CalcError('division by zero');
      return a % b;
    case ProgOp.and:
      return a & b;
    case ProgOp.or:
      return a | b;
    case ProgOp.xor:
      return a ^ b;
    case ProgOp.nor:
      return _wrap(~(a | b));
    case ProgOp.shiftLeft:
      return b > BigInt.from(63) ? BigInt.zero : _wrap(a << b.toInt());
    case ProgOp.shiftRight:
      return b > BigInt.from(63) ? BigInt.zero : a >> b.toInt();
  }
}

BigInt applyUnary(ProgUnary op, BigInt a) {
  switch (op) {
    case ProgUnary.not:
      return _wrap(~a);
    case ProgUnary.negate:
      return _wrap(-a);
    case ProgUnary.shiftLeftOne:
      return _wrap(a << 1);
    case ProgUnary.shiftRightOne:
      return a >> 1;
    case ProgUnary.rotateLeft:
      return _wrap((a << 1) | (a >> 63));
    case ProgUnary.rotateRight:
      return _wrap((a >> 1) | ((a & BigInt.one) << 63));
    case ProgUnary.flip8:
      return _swapBytes(a, 8);
    case ProgUnary.flip16:
      return _swapBytes(a, 2);
  }
}

/// Reverses the order of the low `bytes` bytes (flip₈: all eight, flip₁₆: the low two).
BigInt _swapBytes(BigInt a, int bytes) {
  var out = BigInt.zero;
  for (var i = 0; i < bytes; i++) {
    final byte = (a >> (8 * i)) & BigInt.from(0xff);
    out |= byte << (8 * (bytes - 1 - i));
  }
  final rest = bytes >= 8
      ? BigInt.zero
      : a & ~((BigInt.one << (8 * bytes)) - BigInt.one);
  return _wrap(rest | out);
}

/// The value of `values[0] ops[0] values[1] …` with precedence.
BigInt evaluateProgrammer(List<BigInt> values, List<ProgOp> ops) {
  if (values.isEmpty) return BigInt.zero;
  final output = <BigInt>[values.first];
  final stack = <ProgOp>[];
  void reduce() {
    final op = stack.removeLast();
    final b = output.removeLast();
    final a = output.removeLast();
    output.add(applyBinary(op, a, b));
  }

  for (var i = 0; i < ops.length && i + 1 < values.length; i++) {
    while (stack.isNotEmpty && stack.last.level >= ops[i].level) {
      reduce();
    }
    stack.add(ops[i]);
    output.add(values[i + 1]);
  }
  while (stack.isNotEmpty && output.length >= 2) {
    reduce();
  }
  return output.last;
}

String formatInBase(BigInt value, int base) =>
    value.toRadixString(base).toUpperCase();

class ProgrammerCalculator extends ChangeNotifier {
  int base = 16;
  Encoding encoding = Encoding.ascii;
  bool showBinary = true;

  final List<BigInt> values = [];
  final List<ProgOp> ops = [];

  /// The number being typed, in the current base.
  String entry = '';

  bool evaluated = false;
  BigInt result = BigInt.zero;
  bool error = false;

  bool get showsClear => entry.isNotEmpty || values.isNotEmpty;

  void _changed() => notifyListeners();

  /// The number the bit editor and the one-operand keys work on.
  BigInt get current {
    if (entry.isNotEmpty) return BigInt.parse(entry, radix: base);
    if (evaluated) return result;
    return values.length > ops.length ? values.last : BigInt.zero;
  }

  bool acceptsDigit(String d) {
    final v = int.tryParse(d, radix: 16);
    return v != null && v < base;
  }

  String mainText() {
    if (evaluated) return formatInBase(result, base);
    final out = StringBuffer();
    for (var i = 0; i < values.length; i++) {
      out.write(formatInBase(values[i], base));
      if (i < ops.length) out.write(ops[i].symbol);
    }
    if (values.length == ops.length) out.write(entry.toUpperCase());
    final text = out.toString();
    return text.isEmpty ? '0' : text;
  }

  void _startOver() {
    values.clear();
    ops.clear();
    entry = '';
    evaluated = false;
    error = false;
  }

  /// `digits` is one digit or a pair (FF, 00).
  void digits(String digits) {
    if (evaluated || error) _startOver();
    if (values.length > ops.length) return;
    for (final d in digits.split('')) {
      if (!acceptsDigit(d)) return;
    }
    final next = (entry == '0' ? '' : entry) + digits.toLowerCase();
    final value = BigInt.parse(next.isEmpty ? '0' : next, radix: base);
    if (value > _mask) return;
    entry = next.replaceFirst(RegExp(r'^0+(?=.)'), '');
    _changed();
  }

  void operator(ProgOp op) {
    if (error) _startOver();
    if (evaluated) {
      final r = result;
      _startOver();
      values.add(r);
    } else if (entry.isNotEmpty) {
      values.add(BigInt.parse(entry, radix: base));
      entry = '';
    }
    if (values.isEmpty) values.add(BigInt.zero);
    if (ops.length == values.length) {
      ops[ops.length - 1] = op;
    } else {
      ops.add(op);
    }
    _changed();
  }

  void unary(ProgUnary op) {
    if (error) return;
    final value = applyUnary(op, current);
    _setCurrent(value);
  }

  void _setCurrent(BigInt value) {
    if (evaluated) {
      result = value;
    } else if (values.length > ops.length) {
      values[values.length - 1] = value;
    } else {
      entry = formatInBase(value, base).toLowerCase();
    }
    _changed();
  }

  void toggleBit(int bit) {
    if (bit < 0 || bit > 63 || error) return;
    _setCurrent(current ^ (BigInt.one << bit));
  }

  void equals() {
    if (error) {
      _startOver();
      _changed();
      return;
    }
    if (evaluated) return;
    if (entry.isNotEmpty) {
      values.add(BigInt.parse(entry, radix: base));
      entry = '';
    }
    if (values.isEmpty) return;
    try {
      result = evaluateProgrammer(values, ops);
      evaluated = true;
    } on CalcError {
      error = true;
    }
    values.clear();
    ops.clear();
    _changed();
  }

  void clear() {
    _startOver();
    result = BigInt.zero;
    _changed();
  }

  void backspace() {
    if (evaluated || error) return;
    if (entry.isNotEmpty) {
      entry = entry.substring(0, entry.length - 1);
    } else if (ops.length == values.length && ops.isNotEmpty) {
      ops.removeLast();
      entry = formatInBase(values.removeLast(), base).toLowerCase();
    }
    _changed();
  }

  /// A new base: the typed number keeps its value.
  void setBase(int b) {
    if (b == base || (b != 8 && b != 10 && b != 16)) return;
    final value = entry.isEmpty ? null : BigInt.parse(entry, radix: base);
    base = b;
    if (value != null) entry = value.toRadixString(b);
    _changed();
  }

  void setEncoding(Encoding e) {
    encoding = e;
    _changed();
  }

  void toggleBinary() {
    showBinary = !showBinary;
    _changed();
  }

  /// The character of the current number, if it is printable in the chosen encoding.
  String? character() {
    final v = current;
    final limit = encoding == Encoding.ascii ? 0x7f : 0x10ffff;
    if (v < BigInt.from(0x20) || v > BigInt.from(limit)) return null;
    final code = v.toInt();
    if (code == 0x7f || (code >= 0xd800 && code <= 0xdfff)) return null;
    return String.fromCharCode(code);
  }

  String copyText() => formatInBase(current, base);

  bool paste(String text) {
    final t = text.trim().replaceFirst(RegExp(r'^0[xX]'), '');
    final v = BigInt.tryParse(t, radix: base);
    if (v == null || v.isNegative || v > _mask) return false;
    if (evaluated || error) _startOver();
    if (values.length > ops.length) return false;
    entry = v.toRadixString(base);
    _changed();
    return true;
  }
}
