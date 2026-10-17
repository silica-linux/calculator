// The RPN calculator (kit `Apps/Calculator/RPN`): a four-level stack t, z, y, x. Digits build
// x; "=" is Enter (it copies x up and the next number replaces x); the four operators combine
// y and x, leave the result in x and drop the stack; the keys above the keypad swap, roll and
// drop.

import 'package:flutter/foundation.dart';

import 'calculator.dart' show maxEntryDigits;
import 'expression.dart';
import 'format.dart';
import 'rational.dart';

class RpnCalculator extends ChangeNotifier {
  /// x, y, z, t (index 0 is x).
  final List<Rational> stack = List.filled(4, Rational.zero);

  /// The number being typed for x; empty when x is a value.
  String entry = '';

  /// The next digit pushes the stack up first (after an operation, a swap or a roll); after
  /// Enter, at the start and after a clear it just replaces x.
  bool _lift = false;

  /// The last operation failed (division by zero).
  bool error = false;

  /// C while a number is being typed, AC otherwise.
  bool get showsClear => entry.isNotEmpty;

  Rational get x => entry.isEmpty ? stack[0] : NumberToken(entry).value;

  /// The text of stack line [i] (0 is x, 3 is t).
  String lineText(int i, NumberStyle style, {int places = 8}) {
    if (i == 0 && entry.isNotEmpty) return formatEntry(entry, style);
    return formatNumber(stack[i], style, places: places);
  }

  void _changed() => notifyListeners();

  void _commit() {
    if (entry.isEmpty) return;
    stack[0] = NumberToken(entry == '-' ? '-0' : entry).value;
    entry = '';
  }

  void _pushUp() {
    stack[3] = stack[2];
    stack[2] = stack[1];
    stack[1] = stack[0];
  }

  void digit(String d) {
    error = false;
    if (entry.isEmpty) {
      if (_lift) _pushUp();
      _lift = false;
    }
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
    error = false;
    if (entry.contains('.')) return;
    if (entry.isEmpty) {
      if (_lift) _pushUp();
      _lift = false;
    }
    entry = entry.isEmpty || entry == '-' ? '${entry}0.' : '$entry.';
    _changed();
  }

  /// "=": Enter.
  void enter() {
    error = false;
    _commit();
    _pushUp();
    _lift = false;
    _changed();
  }

  /// Combines y and x with [op]; the result is x, z and t move down.
  void operator(BinOp op) {
    _commit();
    final y = stack[1];
    final x = stack[0];
    final Rational r;
    try {
      r = switch (op) {
        BinOp.add => y + x,
        BinOp.subtract => y - x,
        BinOp.multiply => y * x,
        BinOp.divide => y / x,
        _ => x,
      };
    } on CalcError {
      error = true;
      _changed();
      return;
    }
    error = false;
    stack[0] = r;
    stack[1] = stack[2];
    stack[2] = stack[3];
    _lift = true;
    _changed();
  }

  /// %: x percent of y (y stays).
  void percent() {
    _commit();
    stack[0] = stack[1] * stack[0] / Rational.hundred;
    _lift = true;
    _changed();
  }

  void negate() {
    if (entry.isNotEmpty) {
      entry = entry.startsWith('-') ? entry.substring(1) : '-$entry';
    } else {
      stack[0] = -stack[0];
    }
    error = false;
    _changed();
  }

  void backspace() {
    if (entry.isEmpty) return;
    entry = entry.substring(0, entry.length - 1);
    if (entry == '-') entry = '';
    if (entry.isEmpty) stack[0] = Rational.zero;
    _changed();
  }

  /// C clears the number being typed, AC the whole stack.
  void clear() {
    error = false;
    if (entry.isNotEmpty) {
      entry = '';
      stack[0] = Rational.zero;
    } else {
      for (var i = 0; i < 4; i++) {
        stack[i] = Rational.zero;
      }
    }
    _lift = false;
    _changed();
  }

  void swap() {
    _commit();
    final t = stack[0];
    stack[0] = stack[1];
    stack[1] = t;
    _lift = true;
    _changed();
  }

  /// R↓: x ← y, y ← z, z ← t, t ← x.
  void rollDown() {
    _commit();
    final x = stack[0];
    stack[0] = stack[1];
    stack[1] = stack[2];
    stack[2] = stack[3];
    stack[3] = x;
    _lift = true;
    _changed();
  }

  /// R↑: t ← z, z ← y, y ← x, x ← t.
  void rollUp() {
    _commit();
    final t = stack[3];
    stack[3] = stack[2];
    stack[2] = stack[1];
    stack[1] = stack[0];
    stack[0] = t;
    _lift = true;
    _changed();
  }

  /// Drop: x is lost, y, z and t move down (t stays).
  void drop() {
    entry = '';
    stack[0] = stack[1];
    stack[1] = stack[2];
    stack[2] = stack[3];
    _lift = true;
    _changed();
  }

  /// Paste: a number becomes x.
  bool paste(String text, NumberStyle style) {
    var t = text.trim().replaceAll('−', '-').replaceAll(' ', '');
    t = t.replaceAll(style.group, '').replaceAll(style.decimal, '.');
    if (Rational.tryParse(t) == null) return false;
    if (entry.isEmpty && _lift) _pushUp();
    _lift = false;
    entry = t.toLowerCase();
    _changed();
    return true;
  }

  String copyText(NumberStyle style, {int places = 8}) {
    final plain = NumberStyle(decimal: style.decimal, group: '');
    return formatNumber(x, plain, places: places).replaceAll('−', '-');
  }
}
