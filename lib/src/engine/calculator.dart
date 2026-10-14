// The basic and scientific calculator: what each key does to the expression typed inline
// (calculator.md › Keys and Display). The expression grows on the display ("8÷"); "=" moves
// it to the line above and shows the result; operators have no latched state.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'expression.dart';
import 'format.dart';
import 'rational.dart';

/// Digits at most in one typed number (the display shrinks past 9, CA-01).
const int maxEntryDigits = 20;

class DecimalCalculator extends ChangeNotifier {
  DecimalCalculator({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  /// The committed tokens and the number being typed (`.` as the decimal point).
  final List<Token> tokens = [];
  String entry = '';

  /// After "=": the result on the main line and the expression above it.
  bool evaluated = false;
  Rational result = Rational.zero;
  List<Token> previous = const [];

  /// The last evaluation failed (division by zero, a root of a negative…).
  bool error = false;

  Rational memory = Rational.zero;
  bool hasMemory = false;

  /// "2nd": the alternative functions of some keys.
  bool second = false;
  AngleUnit angle = AngleUnit.degrees;

  /// AC with nothing typed, C as soon as something is (CA-02).
  bool get showsClear => entry.isNotEmpty || tokens.isNotEmpty;

  /// The main line.
  String mainText(NumberStyle style) {
    if (evaluated) return formatNumber(result, style);
    final typed =
        renderTokens(tokens, style) +
        (entry.isEmpty ? '' : formatEntry(entry, style));
    return typed.isEmpty ? '0' : typed;
  }

  /// The line above the main one, after "=" (the expression that was evaluated).
  String? upperText(NumberStyle style) =>
      evaluated || error ? renderTokens(previous, style) : null;

  /// The value the memory keys and Copy use.
  Rational currentValue() {
    if (evaluated) return result;
    if (entry.isNotEmpty && tokens.isEmpty) {
      return NumberToken(entry).value;
    }
    try {
      return evaluate([
        ...tokens,
        if (entry.isNotEmpty) NumberToken(entry),
      ], angle: angle);
    } on CalcError {
      return Rational.zero;
    }
  }

  void _changed() => notifyListeners();

  /// Starts again after a result or an error: the next number replaces it.
  void _startOver() {
    tokens.clear();
    entry = '';
    evaluated = false;
    error = false;
    previous = const [];
  }

  /// After a result the next operator continues from it.
  void _continueFromResult() {
    if (!evaluated) return;
    final value = result;
    _startOver();
    tokens.add(ValueToken(value));
  }

  bool get _lastIsOperand {
    if (tokens.isEmpty) return false;
    final last = tokens.last;
    return last is NumberToken ||
        last is ValueToken ||
        last is ConstantToken ||
        last is CloseToken ||
        last is PostfixToken;
  }

  void _commitEntry() {
    if (entry.isEmpty) return;
    tokens.add(NumberToken(entry == '-' ? '-0' : entry));
    entry = '';
  }

  void _implicitMultiply() {
    if (_lastIsOperand) tokens.add(const OpToken(BinOp.multiply));
  }

  void digit(String d) {
    if (evaluated || error) _startOver();
    if (entry.isEmpty) _implicitMultiply();
    final digits = entry.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digits >= maxEntryDigits) return;
    if (entry == '0' || entry == '-0') {
      entry = entry.replaceFirst('0', d);
    } else {
      entry += d;
    }
    _changed();
  }

  void decimalPoint() {
    if (evaluated || error) _startOver();
    if (entry.contains('.') || entry.contains('e')) return;
    if (entry.isEmpty) _implicitMultiply();
    entry = entry.isEmpty || entry == '-' ? '${entry}0.' : '$entry.';
    _changed();
  }

  /// EE: the exponent of ten of the number being typed.
  void exponent() {
    if (entry.isEmpty || entry.contains('e')) return;
    entry = '${entry}e';
    _changed();
  }

  void operator(BinOp op) {
    if (error) _startOver();
    _continueFromResult();
    _commitEntry();
    if (tokens.isEmpty) tokens.add(const NumberToken('0'));
    final last = tokens.last;
    if (last is OpToken) {
      tokens[tokens.length - 1] = OpToken(op);
    } else if (last is OpenToken || last is FuncToken) {
      return;
    } else {
      tokens.add(OpToken(op));
    }
    _changed();
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
    final expression = [...tokens];
    try {
      result = evaluate(expression, angle: angle);
      error = false;
    } on CalcError {
      error = true;
    }
    previous = expression;
    tokens.clear();
    evaluated = !error;
    _changed();
  }

  /// AC / C (and Esc): everything typed goes, the memory stays.
  void clear() {
    _startOver();
    result = Rational.zero;
    _changed();
  }

  void backspace() {
    if (evaluated || error) return;
    if (entry.isNotEmpty) {
      entry = entry.substring(0, entry.length - 1);
      if (entry == '-') entry = '';
    } else if (tokens.isNotEmpty) {
      final last = tokens.removeLast();
      if (last is NumberToken && last.raw.length > 1) {
        entry = last.raw.substring(0, last.raw.length - 1);
        if (entry == '-') entry = '';
      } else if (last is OpenToken &&
          tokens.isNotEmpty &&
          tokens.last is FuncToken) {
        tokens.removeLast();
      }
    }
    _changed();
  }

  /// ⁺∕₋: the sign of the number being typed (or of its exponent, after EE), or of the result.
  void negate() {
    if (error) return;
    if (evaluated) {
      result = -result;
      _changed();
      return;
    }
    if (entry.endsWith('e')) {
      entry = '$entry-';
    } else if (entry.contains('e-')) {
      entry = entry.replaceFirst('e-', 'e');
    } else if (entry.contains('e') && !entry.endsWith('e')) {
      entry = entry.replaceFirst('e', 'e-');
    } else if (entry.startsWith('-')) {
      entry = entry.substring(1);
    } else if (entry.isNotEmpty) {
      entry = '-$entry';
    } else {
      _implicitMultiply();
      entry = '-0';
    }
    _changed();
  }

  void postfix(Postfix p) {
    if (error) return;
    _continueFromResult();
    _commitEntry();
    if (!_lastIsOperand) return;
    tokens.add(PostfixToken(p));
    _changed();
  }

  /// The index where the operand that ends the expression starts.
  int _operandStart() {
    var i = tokens.length - 1;
    while (i >= 0 && tokens[i] is PostfixToken) {
      i--;
    }
    if (i < 0) return 0;
    if (tokens[i] is CloseToken) {
      var depth = 0;
      for (; i >= 0; i--) {
        if (tokens[i] is CloseToken) depth++;
        if (tokens[i] is OpenToken) depth--;
        if (depth == 0) break;
      }
      if (i > 0 && tokens[i - 1] is FuncToken) i--;
    }
    return math.max(i, 0);
  }

  /// A function of the current number: `sin(30)`; with nothing typed it opens `sin(` for
  /// the argument.
  void function(Func f) {
    if (error) return;
    if (evaluated) {
      final value = result;
      _startOver();
      tokens.addAll([
        FuncToken(f),
        const OpenToken(),
        ValueToken(value),
        const CloseToken(),
      ]);
    } else if (entry.isNotEmpty) {
      tokens.addAll([
        FuncToken(f),
        const OpenToken(),
        NumberToken(entry),
        const CloseToken(),
      ]);
      entry = '';
    } else if (_lastIsOperand) {
      tokens
        ..insertAll(_operandStart(), [FuncToken(f), const OpenToken()])
        ..add(const CloseToken());
    } else {
      tokens.addAll([FuncToken(f), const OpenToken()]);
    }
    _changed();
  }

  void open() {
    if (evaluated || error) _startOver();
    _commitEntry();
    _implicitMultiply();
    tokens.add(const OpenToken());
    _changed();
  }

  void close() {
    if (evaluated || error) return;
    var depth = 0;
    for (final t in tokens) {
      if (t is OpenToken) depth++;
      if (t is CloseToken) depth--;
    }
    if (depth <= 0) return;
    _commitEntry();
    if (!_lastIsOperand) return;
    tokens.add(const CloseToken());
    _changed();
  }

  void constant(Constant c) => _insertOperand(ConstantToken(c));

  /// Rand: a random number between 0 and 1.
  void randomNumber() {
    final digits = _random.nextInt(1 << 30) / (1 << 30);
    _insertOperand(ValueToken(Rational.fromDouble(digits)));
  }

  void _insertOperand(Token operand) {
    if (evaluated || error) _startOver();
    entry = '';
    _implicitMultiply();
    tokens.add(operand);
    _changed();
  }

  void memoryClear() {
    memory = Rational.zero;
    hasMemory = false;
    _changed();
  }

  void memoryAdd() {
    memory = memory + currentValue();
    hasMemory = true;
    _changed();
  }

  void memorySubtract() {
    memory = memory - currentValue();
    hasMemory = true;
    _changed();
  }

  void memoryRecall() => _insertOperand(ValueToken(memory));

  void toggleSecond() {
    second = !second;
    _changed();
  }

  void toggleAngle() {
    angle = angle == AngleUnit.degrees ? AngleUnit.radians : AngleUnit.degrees;
    _changed();
  }

  /// Paste: a number written with either separator (`1.234,5` or `1,234.5`) becomes the entry.
  bool paste(String text, NumberStyle style) {
    var t = text.trim().replaceAll('−', '-').replaceAll(' ', '');
    t = t.replaceAll(style.group, '').replaceAll(style.decimal, '.');
    if (Rational.tryParse(t) == null) return false;
    if (evaluated || error) _startOver();
    _implicitMultiply();
    entry = t.toLowerCase();
    _changed();
    return true;
  }

  /// Copy: what the main line shows, without grouping.
  String copyText(NumberStyle style) {
    final plain = NumberStyle(decimal: style.decimal, group: '');
    if (evaluated) return formatNumber(result, plain).replaceAll('−', '-');
    return formatNumber(currentValue(), plain).replaceAll('−', '-');
  }
}
