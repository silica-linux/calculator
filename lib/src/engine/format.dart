// Numbers as the display writes them: the locale's decimal and thousands separators, at most
// `places` decimals (8 by default, as measured: 2 ÷ 3 = 0,66666667), trailing zeros dropped,
// scientific notation for numbers too large or too small to show that way.

import 'rational.dart';

/// The separators of a locale.
class NumberStyle {
  const NumberStyle({required this.decimal, required this.group});

  final String decimal;
  final String group;

  static const english = NumberStyle(decimal: '.', group: ',');
  static const italian = NumberStyle(decimal: ',', group: '.');

  /// Italian and the other languages that write `1.234,5`; English otherwise.
  static NumberStyle forLanguage(String language) => switch (language) {
    'it' || 'de' || 'es' || 'pt' || 'nl' || 'da' || 'tr' || 'id' => italian,
    'fr' ||
    'sv' ||
    'nb' ||
    'fi' ||
    'cs' ||
    'pl' ||
    'ru' ||
    'uk' => const NumberStyle(decimal: ',', group: ' '),
    _ => english,
  };
}

/// Digits grouped by three from the right (`1234567` → `1.234.567`).
String groupDigits(String digits, String group) {
  if (group.isEmpty || digits.length <= 3) return digits;
  final out = StringBuffer();
  final first = digits.length % 3;
  if (first > 0) out.write(digits.substring(0, first));
  for (var i = first; i < digits.length; i += 3) {
    if (out.isNotEmpty) out.write(group);
    out.write(digits.substring(i, i + 3));
  }
  return out.toString();
}

/// A typed entry (`-1234.5`, `1.2e5`) with the locale's separators, as it is being typed:
/// a trailing decimal point stays visible.
String formatEntry(String entry, NumberStyle style) {
  var text = entry;
  var sign = '';
  if (text.startsWith('-')) {
    sign = '−';
    text = text.substring(1);
  }
  var exponent = '';
  final e = text.indexOf('e');
  if (e >= 0) {
    exponent = text.substring(e).replaceFirst('-', '−');
    text = text.substring(0, e);
  }
  final dot = text.indexOf('.');
  final whole = dot < 0 ? text : text.substring(0, dot);
  final fraction = dot < 0 ? null : text.substring(dot + 1);
  final grouped = groupDigits(whole.isEmpty ? '0' : whole, style.group);
  return '$sign$grouped${fraction == null ? '' : '${style.decimal}$fraction'}$exponent';
}

/// A result with at most `places` decimals.
String formatNumber(Rational value, NumberStyle style, {int places = 8}) {
  if (value.isZero) return '0';
  final negative = value.isNegative;
  final abs = value.abs();
  final scale = BigInt.from(10).pow(places);
  // Rounded half up to `places` decimals.
  final scaled =
      (abs.numerator * scale * BigInt.two + abs.denominator) ~/
      (abs.denominator * BigInt.two);
  final limit = BigInt.from(10).pow(16) * scale;
  if (scaled == BigInt.zero || scaled >= limit) {
    return _scientific(value, style);
  }
  var digits = scaled.toString().padLeft(places + 1, '0');
  final whole = digits.substring(0, digits.length - places);
  var fraction = digits.substring(digits.length - places);
  fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
  final text =
      '${groupDigits(whole, style.group)}${fraction.isEmpty ? '' : '${style.decimal}$fraction'}';
  return negative ? '−$text' : text;
}

/// `1,2345e20` / `1e−10`: eight significant decimals at most.
String _scientific(Rational value, NumberStyle style) {
  final negative = value.isNegative;
  final abs = value.abs();
  // The decimal exponent: digits of the integer part, or zeros after the point.
  var exponent =
      abs.numerator.toString().length - abs.denominator.toString().length;
  var mantissa = abs / Rational.fromInt(10).powInt(exponent);
  if (mantissa.compareTo(Rational.one) < 0) {
    exponent -= 1;
    mantissa = mantissa * Rational.fromInt(10);
  }
  if (mantissa.compareTo(Rational.fromInt(10)) >= 0) {
    exponent += 1;
    mantissa = mantissa / Rational.fromInt(10);
  }
  var text = formatNumber(
    mantissa,
    NumberStyle(decimal: style.decimal, group: ''),
  );
  // Rounding 9,999999999 can give 10.
  if (text == '10') {
    text = '1';
    exponent += 1;
  }
  final e = exponent < 0 ? '−${-exponent}' : '$exponent';
  return '${negative ? '−' : ''}${text}e$e';
}
