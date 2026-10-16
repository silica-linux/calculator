// Geometry of the Calculator window on the Amalfi kit (`App · Calculator`, masters
// `Apps/Calculator/{Basic,Scientific,Programmer}`; `components.md`: keys 48 pt tall, gap 8,
// padding 16, display 72). Sizes in pt (1 pt = 1 px at 1×). The window colours come from the
// `App/Calculator/*` palette (`AmalfiTheme.of(context).colors.calculator`); the app is always
// dark. Only what the kit does not draw (pressed and inactive key fills, the fades) stays
// here, measured (calculator.md, CA-01, CA-02).

import 'package:flutter/widgets.dart';

enum CalcMode { basic, scientific, programmer }

/// The window of each mode: fixed size (kit masters 248 × 412, 664 × 412, 528 × 576).
const Map<CalcMode, Size> windowSize = {
  CalcMode.basic: Size(248, 412),
  CalcMode.scientific: Size(664, 412),
  CalcMode.programmer: Size(528, 576),
};

/// The window controls are drawn by the compositor over the first 96 pt of the toolbar (the
/// kit's `Controls` piece).
const double controlsWidth = 96;

/// Display: the text box is 40 pt high at y 68, 16 pt from each side (`Display/Primary`,
/// Inter Bold 34/40, right-aligned). The expression after "=" sits in the strip above it.
const double displayPadding = 16;
const double displayTop = 68;
const double displayHeight = 40;
const double expressionTop = 50;
const double expressionHeight = 18;

/// Keys: 48 pt tall capsules (circles on the basic pad), 8 apart, 16 from the window edges;
/// the first row at y 124 (basic, scientific) or 232 (programmer, below the bit editor).
const double keyHeight = 48;
const double keyGap = 8;
const double rowPitch = keyHeight + keyGap;
const double keypadLeft = 16;
const Map<CalcMode, double> keypadTop = {
  CalcMode.basic: 124,
  CalcMode.scientific: 124,
  CalcMode.programmer: 232,
};
const Map<CalcMode, double> keyWidth = {
  CalcMode.basic: 48,
  CalcMode.scientific: 56,
  CalcMode.programmer: 64,
};

/// Column pitch of every keypad (key width + gap).
double columnPitch(CalcMode mode) => keyWidth[mode]! + keyGap;

/// The programmer panel (kit `Programmer`): selector row at y 128, 24 pt high; the bit editor
/// 496 × 64 at y 160 with two mono rows 24 apart.
const double selectorTop = 128;
const double selectorHeight = 24;
const double bitEditorTop = 160;
const double bitEditorHeight = 64;
const double bitEditorRadius = 12;

enum KeyRole { digit, function, operator, scientific, programmer }

/// Key fills when pressed and in an inactive window (sRGB, measured); the fills at rest are
/// the palette's.
class KeyColors {
  const KeyColors(this.pressed, this.inactive);
  final Color pressed;
  final Color inactive;
}

const Map<KeyRole, KeyColors> keyColors = {
  KeyRole.digit: KeyColors(Color(0xFF8E8E8E), Color(0xFF4D4D4E)),
  KeyRole.function: KeyColors(Color(0xFFB0B0B0), Color(0xFF545555)),
  KeyRole.operator: KeyColors(Color(0xFFFFAD25), Color(0xFF545555)),
  // Assumption: not measured, the digit's +36 levels.
  KeyRole.scientific: KeyColors(Color(0xFF7C7C7D), Color(0xFF474749)),
  KeyRole.programmer: KeyColors(Color(0xFF7C7C7D), Color(0xFF474749)),
};

/// "2nd" switched on.
const Color secondOn = Color(0xFF7E7E7F);

/// Release fade: ~200 ms for digits and functions, ~330 ms for operators (silica-reference CA-01).
const Duration fadeDigit = Duration(milliseconds: 200);
const Duration fadeOperator = Duration(milliseconds: 330);

/// A typed key lights the matching key for ~80 ms, without a fade (silica-reference CA-01).
const Duration keyboardFlash = Duration(milliseconds: 80);
