// Exact numbers for the calculator: a fraction of two big integers, always reduced, with a
// positive denominator. Sums, products and quotients of typed decimals stay exact, so
// 0.1 + 0.2 is exactly 3/10. Functions with irrational results (sin, ln, roots) go through a
// double and come back with 15 significant digits.

import 'dart:math' as math;

/// The result of an operation outside the domain (division by zero, ln of 0, 1.5!).
class CalcError implements Exception {
  const CalcError(this.reason);
  final String reason;

  @override
  String toString() => 'CalcError($reason)';
}

class Rational implements Comparable<Rational> {
  Rational._(this.numerator, this.denominator);

  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var n = numerator;
    var d = denominator ?? BigInt.one;
    if (d == BigInt.zero) throw const CalcError('division by zero');
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Rational._(n, d);
  }

  factory Rational.fromInt(int value) => Rational(BigInt.from(value));

  final BigInt numerator;
  final BigInt denominator;

  static final Rational zero = Rational.fromInt(0);
  static final Rational one = Rational.fromInt(1);
  static final Rational hundred = Rational.fromInt(100);

  /// A decimal written with `.` and an optional exponent (`12.5`, `-3e-4`, `1.2e5`).
  /// Null for anything else.
  static Rational? tryParse(String text) {
    final match = RegExp(
      r'^([+-]?)(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$',
    ).firstMatch(text.trim());
    if (match == null) return null;
    final whole = match.group(2) ?? '';
    final fraction = match.group(3) ?? '';
    if (whole.isEmpty && fraction.isEmpty) return null;
    final exponentText = match.group(4);
    final exponent = exponentText == null ? 0 : int.tryParse(exponentText);
    if (exponent == null || exponent.abs() > 4000) return null;
    var n = BigInt.parse('${whole.isEmpty ? '0' : whole}$fraction');
    var d = BigInt.from(10).pow(fraction.length);
    if (exponent > 0) n *= BigInt.from(10).pow(exponent);
    if (exponent < 0) d *= BigInt.from(10).pow(-exponent);
    if (match.group(1) == '-') n = -n;
    return Rational(n, d);
  }

  /// A double, kept to 15 significant digits so `sin(30°)` gives exactly 1/2.
  factory Rational.fromDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      throw const CalcError('not a finite number');
    }
    if (value == 0) return zero;
    final parsed = tryParse(value.toStringAsPrecision(15));
    if (parsed == null) throw const CalcError('not a finite number');
    return parsed;
  }

  bool get isZero => numerator == BigInt.zero;
  bool get isNegative => numerator.isNegative;
  bool get isInteger => denominator == BigInt.one;

  Rational operator +(Rational o) => Rational(
    numerator * o.denominator + o.numerator * denominator,
    denominator * o.denominator,
  );
  Rational operator -(Rational o) => Rational(
    numerator * o.denominator - o.numerator * denominator,
    denominator * o.denominator,
  );
  Rational operator *(Rational o) =>
      Rational(numerator * o.numerator, denominator * o.denominator);
  Rational operator /(Rational o) {
    if (o.isZero) throw const CalcError('division by zero');
    return Rational(numerator * o.denominator, denominator * o.numerator);
  }

  Rational operator -() => Rational._(-numerator, denominator);

  Rational abs() => isNegative ? -this : this;

  /// An integer power, exact (negative exponents give the reciprocal).
  Rational powInt(int exponent) {
    if (exponent.abs() > 100000) throw const CalcError('exponent too large');
    if (exponent >= 0) {
      return Rational(numerator.pow(exponent), denominator.pow(exponent));
    }
    if (isZero) throw const CalcError('division by zero');
    return Rational(denominator.pow(-exponent), numerator.pow(-exponent));
  }

  double toDouble() {
    // Scale down huge parts first so the division does not overflow to infinity.
    final shift =
        math.max(numerator.abs().bitLength, denominator.bitLength) - 1000;
    if (shift > 0) {
      return (numerator >> shift).toDouble() /
          (denominator >> shift).toDouble();
    }
    return numerator.toDouble() / denominator.toDouble();
  }

  @override
  int compareTo(Rational o) =>
      (numerator * o.denominator).compareTo(o.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}
