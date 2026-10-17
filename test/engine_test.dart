import 'dart:io';
import 'dart:math' as math;

import 'package:calculator/src/engine/calculator.dart';
import 'package:calculator/src/engine/expression.dart';
import 'package:calculator/src/engine/format.dart';
import 'package:calculator/src/engine/programmer.dart';
import 'package:calculator/src/engine/rational.dart';
import 'package:calculator/src/engine/rpn.dart';
import 'package:calculator/src/engine/units.dart';
import 'package:calculator/src/history.dart';
import 'package:flutter_test/flutter_test.dart';

const it = NumberStyle.italian;
const en = NumberStyle.english;

/// Types `keys` on a fresh calculator: digits, `.`, + - * / ^, `=`, `(` `)`.
DecimalCalculator type(String keys) {
  final c = DecimalCalculator(random: math.Random(1));
  for (final k in keys.split('')) {
    switch (k) {
      case '+':
        c.operator(BinOp.add);
      case '-':
        c.operator(BinOp.subtract);
      case '*':
        c.operator(BinOp.multiply);
      case '/':
        c.operator(BinOp.divide);
      case '^':
        c.operator(BinOp.power);
      case '=':
        c.equals();
      case '.':
        c.decimalPoint();
      case '(':
        c.open();
      case ')':
        c.close();
      case '%':
        c.postfix(Postfix.percent);
      default:
        c.digit(k);
    }
  }
  return c;
}

void main() {
  rpnTests();
  historyTests();
  group('exact decimals', () {
    test('0.1 + 0.2 is exactly 0.3', () {
      final c = type('.1+.2=');
      expect(c.result, Rational.tryParse('0.3'));
      expect(c.mainText(it), '0,3');
      expect(c.mainText(en), '0.3');
    });

    test('2 ÷ 3 shows 8 decimals, rounded', () {
      expect(type('2/3=').mainText(it), '0,66666667');
    });

    test('1 ÷ 3 × 3 is exactly 1', () {
      expect(type('1/3*3=').result, Rational.one);
    });
  });

  group('precedence and percent', () {
    test('× before +, powers before ×, parentheses first', () {
      expect(type('2+3*4=').result, Rational.fromInt(14));
      expect(type('2*3^2=').result, Rational.fromInt(18));
      expect(type('(2+3)*4=').result, Rational.fromInt(20));
      expect(type('2^3^2=').result, Rational.fromInt(512));
    });

    test('a + x% is a + a·x/100; a × x% is a·x/100', () {
      expect(type('50+10%=').result, Rational.fromInt(55));
      expect(type('50-10%=').result, Rational.fromInt(45));
      expect(type('50*10%=').result, Rational.fromInt(5));
      expect(type('8%=').result, Rational.tryParse('0.08'));
    });

    test(
      'unclosed parentheses close at the end, a trailing operator is ignored',
      () {
        expect(type('(2+3=').result, Rational.fromInt(5));
        expect(type('7+=').result, Rational.fromInt(7));
      },
    );
  });

  group('inline expression (CA-02, CA-04)', () {
    test('the display shows the expression, then the result with it above', () {
      final c = type('12+34');
      expect(c.mainText(it), '12+34');
      expect(c.upperText(it), isNull);
      c.equals();
      expect(c.mainText(it), '46');
      expect(c.upperText(it), '12+34');
    });

    test('operators replace each other, no latched state', () {
      final c = type('8+');
      c.operator(BinOp.divide);
      expect(c.mainText(it), '8÷');
    });

    test(
      'AC with nothing typed, C as soon as a digit is typed; C clears all',
      () {
        final c = DecimalCalculator();
        expect(c.showsClear, isFalse);
        c.digit('8');
        expect(c.showsClear, isTrue);
        c.operator(BinOp.divide);
        c.clear();
        expect(c.mainText(it), '0');
        expect(c.showsClear, isFalse);
      },
    );

    test('grouping and the decimal separator follow the locale', () {
      final c = type('1234567.5');
      expect(c.mainText(it), '1.234.567,5');
      expect(c.mainText(en), '1,234,567.5');
    });

    test(
      'after a result an operator continues from it, a digit starts over',
      () {
        final c = type('2+3=');
        c.operator(BinOp.multiply);
        c.digit('2');
        c.equals();
        expect(c.result, Rational.fromInt(10));
        c.digit('7');
        expect(c.mainText(it), '7');
      },
    );

    test('backspace, sign and division by zero', () {
      final c = type('123');
      c.backspace();
      expect(c.mainText(it), '12');
      c.negate();
      expect(c.mainText(it), '−12');
      final z = type('5/0=');
      expect(z.error, isTrue);
      z.digit('1');
      expect(z.error, isFalse);
      expect(z.mainText(it), '1');
    });
  });

  group('scientific', () {
    test('functions wrap the current number', () {
      final c = type('30');
      c.function(Func.sin);
      expect(c.mainText(it), 'sin(30)');
      c.equals();
      expect(c.result, Rational.tryParse('0.5'));
    });

    test('radians, inverse functions, exact roots and logs', () {
      final c = DecimalCalculator()..toggleAngle();
      c.constant(Constant.pi);
      c.function(Func.cos);
      c.equals();
      expect(c.result, Rational.fromInt(-1));
      final r = type('27');
      r.function(Func.cbrt);
      r.equals();
      expect(r.result, Rational.fromInt(3));
      final l = type('1000');
      l.function(Func.log10);
      l.equals();
      expect(l.result, Rational.fromInt(3));
    });

    test('factorial, squares and the y-th root', () {
      final f = type('5');
      f.postfix(Postfix.factorial);
      f.equals();
      expect(f.result, Rational.fromInt(120));
      final s = type('12');
      s.postfix(Postfix.square);
      s.equals();
      expect(s.result, Rational.fromInt(144));
      final y = type('8');
      y.operator(BinOp.root);
      y.digit('3');
      y.equals();
      expect(y.result, Rational.fromInt(2));
    });

    test('EE and the memory', () {
      final c = type('1.5');
      c.exponent();
      c.digit('3');
      expect(c.mainText(it), '1,5e3');
      c.memoryAdd();
      c.clear();
      c.memoryRecall();
      c.operator(BinOp.add);
      c.digit('1');
      c.equals();
      expect(c.result, Rational.fromInt(1501));
    });

    test('domain errors', () {
      final c = type('0');
      c.function(Func.ln);
      c.equals();
      expect(c.error, isTrue);
      final n = type('2.5');
      n.postfix(Postfix.factorial);
      n.equals();
      expect(n.error, isTrue);
    });
  });

  group('formatting', () {
    test('scientific notation for very large and very small numbers', () {
      expect(formatNumber(Rational.fromInt(10).powInt(20), it), '1e20');
      expect(formatNumber(Rational.fromInt(10).powInt(-12), it), '1e−12');
      expect(
        formatNumber(Rational.tryParse('123456789012345678')!, en),
        '1.23456789e17',
      );
    });

    test('paste accepts either separator', () {
      final c = DecimalCalculator();
      expect(c.paste('1.234,5', it), isTrue);
      expect(c.mainText(it), '1.234,5');
      expect(c.paste('hello', it), isFalse);
      expect(c.copyText(it), '1234,5');
    });
  });

  group('programmer', () {
    test('hex digits, precedence and 64-bit wrap', () {
      final p = ProgrammerCalculator();
      p.digits('F');
      p.digits('F');
      p.operator(ProgOp.add);
      p.digits('1');
      p.operator(ProgOp.multiply);
      p.digits('2');
      p.equals();
      expect(p.mainText(), '101');
      p.clear();
      p.digits('0');
      p.unary(ProgUnary.not);
      expect(p.mainText(), 'FFFFFFFFFFFFFFFF');
      p.unary(ProgUnary.negate);
      expect(p.mainText(), '1');
    });

    test('bases keep the value, digits outside the base are refused', () {
      final p = ProgrammerCalculator()
        ..digits('F')
        ..digits('F');
      p.setBase(10);
      expect(p.mainText(), '255');
      p.digits('A');
      expect(p.mainText(), '255');
      p.setBase(8);
      expect(p.mainText(), '377');
      expect(p.acceptsDigit('8'), isFalse);
    });

    test('bits, rotations and byte flips', () {
      final p = ProgrammerCalculator()..toggleBit(63);
      expect(p.current, BigInt.one << 63);
      p.unary(ProgUnary.rotateLeft);
      expect(p.current, BigInt.one);
      p.clear();
      p.digits('12');
      p.digits('34');
      p.unary(ProgUnary.flip16);
      expect(p.mainText(), '3412');
      p.clear();
      p.digits('5');
      p.operator(ProgOp.divide);
      p.digits('0');
      p.equals();
      expect(p.error, isTrue);
    });

    test('parentheses change the grouping', () {
      final p = ProgrammerCalculator()..setBase(10);
      p.open();
      p.digits('2');
      p.operator(ProgOp.add);
      p.digits('3');
      p.close();
      p.operator(ProgOp.multiply);
      p.digits('4');
      expect(p.mainText(), '(2+3)×4');
      p.equals();
      expect(p.mainText(), '20');
    });

    test('the character of the number', () {
      final p = ProgrammerCalculator()..digits('41');
      expect(p.character(), 'A');
      p.clear();
      p.digits('E9');
      expect(p.character(), isNull);
      p.setEncoding(Encoding.unicode);
      expect(p.character(), 'é');
    });
  });

  test('View › Decimal Places rounds the results, 0–15', () {
    final c = DecimalCalculator()
      ..digit('2')
      ..operator(BinOp.divide)
      ..digit('3')
      ..equals();
    expect(c.mainText(NumberStyle.english), '0.66666667');
    c.setPlaces(3);
    expect(c.mainText(NumberStyle.english), '0.667');
    expect(c.copyText(NumberStyle.english), '0.667');
    c.setPlaces(0);
    expect(c.mainText(NumberStyle.english), '1');
    c.setPlaces(99);
    expect(c.places, maxPlaces);
    c.setPlaces(-4);
    expect(c.places, 0);
  });
}

void historyTests() {
  test(
    'history: saved newest first, grouped by period, hostile files ignored',
    () {
      final dir = Directory.systemTemp.createTempSync('calc-history');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/calculator/history.json';
      final now = DateTime(2026, 10, 17, 12);
      HistoryStore(path)
        ..add('1+1', '2', now.subtract(const Duration(days: 3)))
        ..add('2×3', '6', now);
      final again = HistoryStore.forUser({'XDG_DATA_HOME': dir.path});
      expect(again.records.map((r) => r.result), ['6', '2']);
      expect(
        [for (final r in again.records) HistoryStore.periodOf(r, now)],
        [HistoryPeriod.today, HistoryPeriod.last30Days],
      );
      expect(
        HistoryStore.periodOf(
          HistoryRecord('x', 'y', now.subtract(const Duration(days: 90))),
          now,
        ),
        HistoryPeriod.older,
      );
      File(path).writeAsStringSync('{not json');
      expect(
        HistoryStore.forUser({'XDG_DATA_HOME': dir.path}).records,
        isEmpty,
      );
    },
  );
}

void rpnTests() {
  group('rpn', () {
    RpnCalculator typeRpn(String keys) {
      final c = RpnCalculator();
      for (final k in keys.split('')) {
        switch (k) {
          case ' ':
            c.enter();
          case '+':
            c.operator(BinOp.add);
          case '-':
            c.operator(BinOp.subtract);
          case '*':
            c.operator(BinOp.multiply);
          case '/':
            c.operator(BinOp.divide);
          case '.':
            c.decimalPoint();
          default:
            c.digit(k);
        }
      }
      return c;
    }

    String x(RpnCalculator c) => c.lineText(0, en);

    test('Enter lifts the stack, operators combine y and x', () {
      expect(x(typeRpn('12 3+')), '15');
      expect(x(typeRpn('12 3-')), '9');
      expect(x(typeRpn('12 3*')), '36');
      expect(x(typeRpn('12 4/')), '3');
      final c = typeRpn('4 3 12 0');
      expect(
        [for (var i = 0; i < 4; i++) c.lineText(i, en)],
        ['0', '12', '3', '4'],
      );
    });

    test('a chain: (2 + 3) × 4', () {
      expect(x(typeRpn('2 3+4*')), '20');
    });

    test('division by zero is an error and keeps the stack', () {
      final c = typeRpn('5 0/');
      expect(c.error, isTrue);
      expect(c.stack[0], Rational.zero);
      expect(c.stack[1], Rational.fromInt(5));
    });

    test('swap, rolls and drop', () {
      final c = typeRpn('1 2 3 4');
      c.enter();
      // t z y x = 2 3 4 4 after Enter; make it distinct.
      c.drop();
      c.digit('9');
      expect(
        [for (var i = 3; i >= 0; i--) c.lineText(i, en)],
        ['2', '3', '4', '9'],
      );
      c.swap();
      expect(c.lineText(0, en), '4');
      expect(c.lineText(1, en), '9');
      c.rollDown();
      expect(
        [for (var i = 3; i >= 0; i--) c.lineText(i, en)],
        ['4', '2', '3', '9'],
      );
      c.rollUp();
      expect(c.lineText(0, en), '4');
      expect(c.lineText(3, en), '2');
    });

    test('C clears the entry, AC the stack; negate and percent', () {
      final c = typeRpn('50 8');
      c.percent();
      expect(x(c), '4');
      c.negate();
      expect(x(c), '−4');
      c.digit('7');
      c.clear();
      expect(x(c), '0');
      c.clear();
      expect(c.stack.every((v) => v.isZero), isTrue);
    });
  });

  group('units', () {
    double conv(String from, String to, double v) =>
        convertValue(v, unitById(from), unitById(to));

    test('length, mass, time, data', () {
      expect(conv('km', 'mi', 1), closeTo(0.621371, 1e-6));
      expect(conv('in', 'cm', 1), closeTo(2.54, 1e-12));
      expect(conv('lb', 'kg', 1), closeTo(0.45359237, 1e-12));
      expect(conv('h', 'min', 2), closeTo(120, 1e-9));
      expect(conv('gib', 'mb', 1), closeTo(1073.741824, 1e-9));
    });

    test('temperature is affine', () {
      expect(conv('c', 'f', 100), closeTo(212, 1e-9));
      expect(conv('f', 'c', -40), closeTo(-40, 1e-9));
      expect(conv('c', 'k', 0), closeTo(273.15, 1e-9));
      expect(conv('k', 'f', 0), closeTo(-459.67, 1e-9));
    });

    test('every category has two units and a default pair of its own', () {
      for (final c in UnitCategory.values) {
        expect(c.units.length, greaterThanOrEqualTo(3));
        final (a, b) = defaultPair(c);
        expect(a.category, c);
        expect(b.category, c);
        expect(a, isNot(b));
      }
      expect(allUnits.map((u) => u.id).toSet().length, allUnits.length);
    });
  });
}
