// The expression typed inline on the display ("12+34", "sin(30)×2"): a list of tokens, how
// the display writes them, and their value with the usual precedence (powers, then × ÷, then
// + −). Percent follows the common calculator rule: `50 + 10%` is 55, `50 × 10%` is 5.

import 'dart:math' as math;

import 'format.dart';
import 'rational.dart';

enum BinOp {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷'),
  power('^'),

  /// `x yˣ y`: y to the x (the exponent is typed first).
  powerReversed('ʸˣ'),

  /// `x ʸ√ y`: the y-th root of x.
  root('ʸ√'),

  /// `x logᵧ y`: the logarithm of x in base y.
  logBase('logᵧ');

  const BinOp(this.symbol);
  final String symbol;
}

enum Func {
  sin('sin'),
  cos('cos'),
  tan('tan'),
  asin('sin⁻¹'),
  acos('cos⁻¹'),
  atan('tan⁻¹'),
  sinh('sinh'),
  cosh('cosh'),
  tanh('tanh'),
  asinh('sinh⁻¹'),
  acosh('cosh⁻¹'),
  atanh('tanh⁻¹'),
  ln('ln'),
  log10('log₁₀'),
  log2('log₂'),
  exp('e^'),
  tenPow('10^'),
  twoPow('2^'),
  sqrt('√'),
  cbrt('∛'),
  reciprocal('1/');

  const Func(this.symbol);
  final String symbol;
}

enum Postfix {
  square('²'),
  cube('³'),
  factorial('!'),
  percent('%');

  const Postfix(this.symbol);
  final String symbol;
}

enum Constant {
  pi('π'),
  e('e');

  const Constant(this.symbol);
  final String symbol;
}

sealed class Token {
  const Token();
}

/// A number as typed (`12.5`, `-3`, `1.2e5`), `.` as the decimal point.
class NumberToken extends Token {
  const NumberToken(this.raw);
  final String raw;

  Rational get value {
    final text = raw.endsWith('e') || raw.endsWith('e-')
        ? raw.substring(0, raw.indexOf('e'))
        : raw;
    return Rational.tryParse(text.endsWith('.') ? '${text}0' : text) ??
        Rational.zero;
  }
}

/// An exact value carried over (a previous result, the memory).
class ValueToken extends Token {
  const ValueToken(this.value);
  final Rational value;
}

class ConstantToken extends Token {
  const ConstantToken(this.constant);
  final Constant constant;
}

class OpToken extends Token {
  const OpToken(this.op);
  final BinOp op;
}

class FuncToken extends Token {
  const FuncToken(this.func);
  final Func func;
}

class PostfixToken extends Token {
  const PostfixToken(this.postfix);
  final Postfix postfix;
}

class OpenToken extends Token {
  const OpenToken();
}

class CloseToken extends Token {
  const CloseToken();
}

/// How the display writes the tokens.
String renderTokens(List<Token> tokens, NumberStyle style) {
  final out = StringBuffer();
  for (final t in tokens) {
    out.write(switch (t) {
      NumberToken(:final raw) => formatEntry(raw, style),
      ValueToken(:final value) => formatNumber(value, style),
      ConstantToken(:final constant) => constant.symbol,
      OpToken(:final op) => op.symbol,
      FuncToken(:final func) => func.symbol,
      PostfixToken(:final postfix) => postfix.symbol,
      OpenToken() => '(',
      CloseToken() => ')',
    });
  }
  return out.toString();
}

/// Angles for the trigonometric functions.
enum AngleUnit { degrees, radians }

/// The value of `tokens`; unclosed parentheses are closed at the end, a trailing operator is
/// ignored. Throws [CalcError] outside the domain.
Rational evaluate(List<Token> tokens, {AngleUnit angle = AngleUnit.degrees}) {
  final list = [...tokens];
  while (list.isNotEmpty && list.last is OpToken) {
    list.removeLast();
  }
  if (list.isEmpty) return Rational.zero;
  final parser = _Parser(list, angle);
  final value = parser.expression().value;
  if (parser.position < list.length) {
    throw const CalcError('unexpected token');
  }
  return value;
}

/// A value, and for a term that is just `x%`, the `x` (for `a + x%`).
class _Value {
  const _Value(this.value, [this.percentOf]);
  final Rational value;
  final Rational? percentOf;
}

class _Parser {
  _Parser(this.tokens, this.angle);

  final List<Token> tokens;
  final AngleUnit angle;
  int position = 0;

  Token? get _peek => position < tokens.length ? tokens[position] : null;

  _Value expression() {
    var left = term();
    while (true) {
      final t = _peek;
      if (t is! OpToken || (t.op != BinOp.add && t.op != BinOp.subtract)) {
        return left;
      }
      position++;
      final right = term();
      // a + x% is a + a·x/100.
      final amount = right.percentOf == null
          ? right.value
          : left.value * right.percentOf! / Rational.hundred;
      left = _Value(
        t.op == BinOp.add ? left.value + amount : left.value - amount,
      );
    }
  }

  _Value term() {
    var left = unary();
    while (true) {
      final t = _peek;
      if (t is! OpToken || (t.op != BinOp.multiply && t.op != BinOp.divide)) {
        return left;
      }
      position++;
      final right = unary();
      left = _Value(
        t.op == BinOp.multiply
            ? left.value * right.value
            : left.value / right.value,
      );
    }
  }

  _Value unary() {
    final t = _peek;
    if (t is OpToken && t.op == BinOp.subtract) {
      position++;
      return _Value(-unary().value);
    }
    return power();
  }

  _Value power() {
    final base = postfix();
    final t = _peek;
    if (t is OpToken &&
        (t.op == BinOp.power ||
            t.op == BinOp.powerReversed ||
            t.op == BinOp.root ||
            t.op == BinOp.logBase)) {
      position++;
      // Right associative: 2^3^2 is 2^9.
      final exponent = unary().value;
      return _Value(switch (t.op) {
        BinOp.power => _pow(base.value, exponent),
        BinOp.powerReversed => _pow(exponent, base.value),
        BinOp.root => _root(base.value, exponent),
        _ => _logBase(base.value, exponent),
      });
    }
    return base;
  }

  _Value postfix() {
    var value = primary();
    Rational? percentOf;
    while (_peek is PostfixToken) {
      final p = (_peek! as PostfixToken).postfix;
      position++;
      percentOf = null;
      switch (p) {
        case Postfix.square:
          value = value.powInt(2);
        case Postfix.cube:
          value = value.powInt(3);
        case Postfix.factorial:
          value = _factorial(value);
        case Postfix.percent:
          percentOf = value;
          value = value / Rational.hundred;
      }
    }
    return _Value(value, percentOf);
  }

  Rational primary() {
    final t = _peek;
    position++;
    switch (t) {
      case NumberToken():
        return t.value;
      case ValueToken(:final value):
        return value;
      case ConstantToken(:final constant):
        return Rational.fromDouble(constant == Constant.pi ? math.pi : math.e);
      case OpenToken():
        final inner = expression().value;
        if (_peek is CloseToken) position++;
        return inner;
      case FuncToken(:final func):
        Rational argument;
        if (_peek is OpenToken) {
          position++;
          argument = expression().value;
          if (_peek is CloseToken) position++;
        } else {
          argument = postfix().value;
        }
        return _apply(func, argument);
      default:
        throw const CalcError('missing operand');
    }
  }

  double _toRadians(double x) =>
      angle == AngleUnit.degrees ? x * math.pi / 180 : x;
  double _fromRadians(double x) =>
      angle == AngleUnit.degrees ? x * 180 / math.pi : x;

  Rational _apply(Func f, Rational a) {
    final x = a.toDouble();
    switch (f) {
      case Func.sqrt:
        if (a.isNegative) throw const CalcError('square root of a negative');
        return _exactRoot(a, 2) ?? Rational.fromDouble(math.sqrt(x));
      case Func.cbrt:
        return _root(a, Rational.fromInt(3));
      case Func.reciprocal:
        return Rational.one / a;
      case Func.tenPow:
        return _pow(Rational.fromInt(10), a);
      case Func.twoPow:
        return _pow(Rational.fromInt(2), a);
      case Func.exp:
        return Rational.fromDouble(math.exp(x));
      case Func.ln:
        if (x <= 0) throw const CalcError('logarithm of a non-positive number');
        return Rational.fromDouble(math.log(x));
      case Func.log10:
        if (x <= 0) throw const CalcError('logarithm of a non-positive number');
        return _exactLog(a, 10) ?? Rational.fromDouble(math.log(x) / math.ln10);
      case Func.log2:
        if (x <= 0) throw const CalcError('logarithm of a non-positive number');
        return _exactLog(a, 2) ?? Rational.fromDouble(math.log(x) / math.ln2);
      case Func.sin:
        return Rational.fromDouble(_clean(math.sin(_toRadians(x))));
      case Func.cos:
        return Rational.fromDouble(_clean(math.cos(_toRadians(x))));
      case Func.tan:
        final c = _clean(math.cos(_toRadians(x)));
        if (c == 0) throw const CalcError('tangent undefined');
        return Rational.fromDouble(_clean(math.tan(_toRadians(x))));
      case Func.asin:
        if (x.abs() > 1) throw const CalcError('outside [-1, 1]');
        return Rational.fromDouble(_fromRadians(math.asin(x)));
      case Func.acos:
        if (x.abs() > 1) throw const CalcError('outside [-1, 1]');
        return Rational.fromDouble(_fromRadians(math.acos(x)));
      case Func.atan:
        return Rational.fromDouble(_fromRadians(math.atan(x)));
      case Func.sinh:
        return Rational.fromDouble((math.exp(x) - math.exp(-x)) / 2);
      case Func.cosh:
        return Rational.fromDouble((math.exp(x) + math.exp(-x)) / 2);
      case Func.tanh:
        final p = math.exp(x), m = math.exp(-x);
        return Rational.fromDouble((p - m) / (p + m));
      case Func.asinh:
        return Rational.fromDouble(math.log(x + math.sqrt(x * x + 1)));
      case Func.acosh:
        if (x < 1) throw const CalcError('outside the domain');
        return Rational.fromDouble(math.log(x + math.sqrt(x * x - 1)));
      case Func.atanh:
        if (x.abs() >= 1) throw const CalcError('outside the domain');
        return Rational.fromDouble(0.5 * math.log((1 + x) / (1 - x)));
    }
  }
}

/// Rounding noise of the trigonometric functions (sin 180° = 1.2e-16) becomes 0.
double _clean(double x) => x.abs() < 1e-13 ? 0 : x;

Rational _pow(Rational base, Rational exponent) {
  if (exponent.isInteger) {
    final e = exponent.numerator;
    if (e.abs() > BigInt.from(100000))
      throw const CalcError('exponent too large');
    return base.powInt(e.toInt());
  }
  if (base.isNegative) throw const CalcError('fractional power of a negative');
  if (base.isZero) return Rational.zero;
  // An exact root when the exponent is 1/n and the base a perfect power.
  if (exponent.numerator == BigInt.one) {
    final exact = _exactRoot(base, exponent.denominator.toInt());
    if (exact != null) return exact;
  }
  return Rational.fromDouble(
    math.pow(base.toDouble(), exponent.toDouble()).toDouble(),
  );
}

/// The `n`-th root of `x`; odd roots of negatives are negative.
Rational _root(Rational x, Rational n) {
  if (n.isZero) throw const CalcError('zeroth root');
  if (n.isInteger) {
    final k = n.numerator.toInt();
    if (x.isNegative) {
      if (k.isEven) throw const CalcError('even root of a negative');
      return -_root(-x, n);
    }
    final exact = _exactRoot(x, k.abs());
    if (exact != null) return k > 0 ? exact : Rational.one / exact;
  }
  if (x.isNegative) throw const CalcError('root of a negative');
  return Rational.fromDouble(
    math.pow(x.toDouble(), 1 / n.toDouble()).toDouble(),
  );
}

/// `x` is a perfect `k`-th power of a fraction: its exact root, otherwise null.
Rational? _exactRoot(Rational x, int k) {
  if (k <= 0 || k > 64 || x.isNegative) return null;
  final n = _intRoot(x.numerator, k);
  final d = _intRoot(x.denominator, k);
  if (n == null || d == null) return null;
  return Rational(n, d);
}

BigInt? _intRoot(BigInt value, int k) {
  if (value == BigInt.zero) return BigInt.zero;
  final guess = BigInt.from(math.pow(value.toDouble(), 1 / k).round());
  for (final c in [guess - BigInt.one, guess, guess + BigInt.one]) {
    if (c >= BigInt.zero && c.pow(k) == value) return c;
  }
  return null;
}

/// log base `b` of x when x is an exact integer power of b.
Rational? _exactLog(Rational x, int b) {
  if (!x.isInteger && x.numerator != BigInt.one) return null;
  final big = BigInt.from(b);
  if (x.isInteger) {
    var v = x.numerator;
    var k = 0;
    while (v > BigInt.one && v % big == BigInt.zero) {
      v = v ~/ big;
      k++;
    }
    return v == BigInt.one ? Rational.fromInt(k) : null;
  }
  final inverse = _exactLog(Rational(x.denominator), b);
  return inverse == null ? null : -inverse;
}

Rational _logBase(Rational x, Rational base) {
  final xb = x.toDouble(), bb = base.toDouble();
  if (xb <= 0 || bb <= 0 || bb == 1) {
    throw const CalcError('logarithm outside the domain');
  }
  return Rational.fromDouble(math.log(xb) / math.log(bb));
}

Rational _factorial(Rational x) {
  if (!x.isInteger || x.isNegative) {
    throw const CalcError('factorial of a non-natural number');
  }
  final n = x.numerator.toInt();
  if (n > 3000) throw const CalcError('factorial too large');
  var result = BigInt.one;
  for (var i = 2; i <= n; i++) {
    result *= BigInt.from(i);
  }
  return Rational(result);
}
