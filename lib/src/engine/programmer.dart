// The programmer mode (calculator.md › Display, CA-01): 64-bit integers shown in
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

/// A token of the programmer expression.
sealed class ProgToken {
  const ProgToken();
}

class ProgValue extends ProgToken {
  const ProgValue(this.value);
  final BigInt value;
}

class ProgOperator extends ProgToken {
  const ProgOperator(this.op);
  final ProgOp op;
}

class ProgOpen extends ProgToken {
  const ProgOpen();
}

class ProgClose extends ProgToken {
  const ProgClose();
}

/// The value of the tokens with precedence and parentheses (shunting-yard); unclosed
/// parentheses close at the end, a trailing operator is ignored.
BigInt evaluateProgrammer(List<ProgToken> tokens) {
  final output = <BigInt>[];
  final stack = <ProgToken>[];
  void reduce() {
    final op = (stack.removeLast() as ProgOperator).op;
    if (output.length < 2) throw const CalcError('missing operand');
    final b = output.removeLast();
    final a = output.removeLast();
    output.add(applyBinary(op, a, b));
  }

  final list = [...tokens];
  while (list.isNotEmpty && list.last is ProgOperator) {
    list.removeLast();
  }
  for (final t in list) {
    switch (t) {
      case ProgValue(:final value):
        output.add(value);
      case ProgOperator(:final op):
        while (stack.isNotEmpty &&
            stack.last is ProgOperator &&
            (stack.last as ProgOperator).op.level >= op.level) {
          reduce();
        }
        stack.add(t);
      case ProgOpen():
        stack.add(t);
      case ProgClose():
        while (stack.isNotEmpty && stack.last is! ProgOpen) {
          reduce();
        }
        if (stack.isNotEmpty) stack.removeLast();
    }
  }
  while (stack.isNotEmpty) {
    if (stack.last is ProgOpen) {
      stack.removeLast();
    } else {
      reduce();
    }
  }
  if (output.isEmpty) return BigInt.zero;
  return output.last;
}

String formatInBase(BigInt value, int base) =>
    value.toRadixString(base).toUpperCase();

class ProgrammerCalculator extends ChangeNotifier {
  int base = 16;
  Encoding encoding = Encoding.ascii;
  bool showBinary = true;

  final List<ProgToken> tokens = [];

  /// The number being typed, in the current base.
  String entry = '';

  bool evaluated = false;
  BigInt result = BigInt.zero;
  bool error = false;

  bool get showsClear => entry.isNotEmpty || tokens.isNotEmpty;

  void _changed() => notifyListeners();

  bool get _lastIsOperand =>
      tokens.isNotEmpty &&
      (tokens.last is ProgValue || tokens.last is ProgClose);

  /// The number the bit editor and the one-operand keys work on.
  BigInt get current {
    if (entry.isNotEmpty) return BigInt.parse(entry, radix: base);
    if (evaluated) return result;
    if (tokens.isNotEmpty && tokens.last is ProgValue) {
      return (tokens.last as ProgValue).value;
    }
    return BigInt.zero;
  }

  bool acceptsDigit(String d) {
    final v = int.tryParse(d, radix: 16);
    return v != null && v < base;
  }

  String mainText() {
    if (evaluated) return formatInBase(result, base);
    final out = StringBuffer();
    for (final t in tokens) {
      out.write(switch (t) {
        ProgValue(:final value) => formatInBase(value, base),
        ProgOperator(:final op) => op.symbol,
        ProgOpen() => '(',
        ProgClose() => ')',
      });
    }
    out.write(entry.toUpperCase());
    final text = out.toString();
    return text.isEmpty ? '0' : text;
  }

  void _startOver() {
    tokens.clear();
    entry = '';
    evaluated = false;
    error = false;
  }

  void _commitEntry() {
    if (entry.isEmpty) return;
    tokens.add(ProgValue(BigInt.parse(entry, radix: base)));
    entry = '';
  }

  /// `digits` is one digit or a pair (FF, 00).
  void digits(String digits) {
    if (evaluated || error) _startOver();
    if (_lastIsOperand) return;
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
      tokens.add(ProgValue(r));
    }
    _commitEntry();
    if (tokens.isEmpty) tokens.add(ProgValue(BigInt.zero));
    final last = tokens.last;
    if (last is ProgOperator) {
      tokens[tokens.length - 1] = ProgOperator(op);
    } else if (last is ProgOpen) {
      return;
    } else {
      tokens.add(ProgOperator(op));
    }
    _changed();
  }

  void open() {
    if (evaluated || error) _startOver();
    if (entry.isNotEmpty || _lastIsOperand) return;
    tokens.add(const ProgOpen());
    _changed();
  }

  void close() {
    if (evaluated || error) return;
    var depth = 0;
    for (final t in tokens) {
      if (t is ProgOpen) depth++;
      if (t is ProgClose) depth--;
    }
    if (depth <= 0) return;
    _commitEntry();
    if (!_lastIsOperand) return;
    tokens.add(const ProgClose());
    _changed();
  }

  void unary(ProgUnary op) {
    if (error) return;
    _setCurrent(applyUnary(op, current));
  }

  void _setCurrent(BigInt value) {
    if (evaluated) {
      result = value;
    } else if (entry.isEmpty && tokens.isNotEmpty && tokens.last is ProgValue) {
      tokens[tokens.length - 1] = ProgValue(value);
    } else if (!_lastIsOperand) {
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
    _commitEntry();
    if (tokens.isEmpty) return;
    try {
      result = evaluateProgrammer(tokens);
      evaluated = true;
    } on CalcError {
      error = true;
    }
    tokens.clear();
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
    } else if (tokens.isNotEmpty) {
      final last = tokens.removeLast();
      if (last is ProgValue) {
        final text = formatInBase(last.value, base).toLowerCase();
        entry = text.substring(0, text.length - 1);
      }
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
    final limit = encoding == Encoding.ascii ? 0x7e : 0x10ffff;
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
    if (_lastIsOperand) return false;
    entry = v.toRadixString(base);
    _changed();
    return true;
  }
}
