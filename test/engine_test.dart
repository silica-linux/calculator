import 'dart:math' as math;

import 'package:calculator/src/engine/calculator.dart';
import 'package:calculator/src/engine/expression.dart';
import 'package:calculator/src/engine/format.dart';
import 'package:calculator/src/engine/programmer.dart';
import 'package:calculator/src/engine/rational.dart';
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
}
