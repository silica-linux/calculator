// Measured colours and geometry (calculator.md, CA-01). The app is always dark: the system
// appearance does not change it. Sizes in pt (1 pt = 1 px at 1×).

import 'package:flutter/widgets.dart';

enum CalcMode { basic, scientific, programmer }

/// The window of each mode: fixed size, the keypad 10 pt from the left, right and bottom.
const Map<CalcMode, Size> windowSize = {
  CalcMode.basic: Size(230, 408),
  CalcMode.scientific: Size(674, 408),
  CalcMode.programmer: Size(488, 582),
};

// The toolbar is silica_ui's `toolbarHeight` (52 pt, AX `AXToolbar` 230 × 52).

/// Window background and its inner rim (Ossido draws the 1 pt outer outline `#060606`).
const Color windowFill = Color(0xFF272727);
const Color windowRim = Color(0xFF3D3D3D);

/// Toolbar buttons: 36 pt circles at x 96 (history) and width − 44 (mode), y 8.
const double toolbarButton = 36;
const double toolbarButtonTop = 8;
const double historyButtonLeft = 96;
const Color toolbarButtonFill = Color(0xFF444546);

/// Toolbar buttons in an inactive window, and the Mode button under the pointer (CA-02:
/// the only control with a hover state).
const Color toolbarButtonInactive = Color(0xFF3B3B3C);
const Color toolbarButtonHover = Color(0xFF4E4E4F);
const Color toolbarButtonOutline = Color(0xFF0F0F0F);

/// Display: the ink ends 12–13 pt from the window edge (x 217–218 on 230; the text box is
/// 10 pt from it, Inter's side bearing does the rest), main baseline at y 119, the expression
/// line above at y 81. Inter 29 and 21 give the measured glyph heights (22 and 15–16 px).
const double displayRightPadding = 10;
const double mainBaseline = 119;
const double upperBaseline = 81;
const double mainFontSize = 29;
const double upperFontSize = 21;
const Color displayText = Color(0xFFDEDEDE);
const Color displaySecondary = Color(0xFF9E9E9E);

/// Keys: rows of 48 at a 54 pt pitch; the first row at y 133 (basic, scientific) or 254
/// (programmer).
const double keyHeight = 48;
const double rowPitch = 54;
const double keypadLeft = 10;
const Map<CalcMode, double> keypadTop = {
  CalcMode.basic: 133,
  CalcMode.scientific: 133,
  CalcMode.programmer: 254,
};
const Map<CalcMode, double> keyWidth = {
  CalcMode.basic: 48,
  CalcMode.scientific: 60,
  CalcMode.programmer: 62,
};

/// Left edges of the programmer columns (x 1010, 1078, 1145, … on the reference screen).
const List<double> programmerColumns = [10, 78, 145, 213, 281, 349, 416];

/// Column pitch of the basic and scientific keypads.
const Map<CalcMode, double> columnPitch = {
  CalcMode.basic: 54,
  CalcMode.scientific: 66,
};

enum KeyRole { digit, function, operator, scientific, programmer }

/// Key fills at rest and pressed (sRGB), and in an inactive window.
class KeyColors {
  const KeyColors(this.rest, this.pressed, this.inactive);
  final Color rest;
  final Color pressed;
  final Color inactive;
}

const Map<KeyRole, KeyColors> keyColors = {
  KeyRole.digit: KeyColors(
    Color(0xFF6A6A6A),
    Color(0xFF8E8E8E),
    Color(0xFF4D4D4E),
  ),
  KeyRole.function: KeyColors(
    Color(0xFF919191),
    Color(0xFFB0B0B0),
    Color(0xFF545555),
  ),
  KeyRole.operator: KeyColors(
    Color(0xFFFF8B00),
    Color(0xFFFFAD25),
    Color(0xFF545555),
  ),
  // Pressed scientific and programmer keys: not measured, the digit's +36 levels (estimated).
  KeyRole.scientific: KeyColors(
    Color(0xFF585859),
    Color(0xFF7C7C7D),
    Color(0xFF474749),
  ),
  KeyRole.programmer: KeyColors(
    Color(0xFF575758),
    Color(0xFF7B7B7C),
    Color(0xFF474749),
  ),
};

/// "2nd" switched on.
const Color secondOn = Color(0xFF7E7E7F);

/// The 1 pt dark outline around every key.
const Color keyOutline = Color(0xFF0D0D0D);

/// Release fade: ~200 ms for digits and functions, ~330 ms for operators (silica-reference CA-01).
const Duration fadeDigit = Duration(milliseconds: 200);
const Duration fadeOperator = Duration(milliseconds: 330);

/// A typed key lights the matching key for ~80 ms, without a fade (silica-reference CA-01).
const Duration keyboardFlash = Duration(milliseconds: 80);

/// Programmer mode: divider at y 132, segmented controls 24 pt high at y 137, the bit
/// editor rows below (silica-reference CA-01).
const double programmerDividerY = 132;
const Color programmerDivider = Color(0xFF3C3C3D);
const double segmentTop = 137;
const double segmentHeight = 24;
const Color segmentFill = Color(0xFF373738);
const Color segmentChosen = Color(0xFFFF960E);

/// The chosen base segment in an inactive window (CA-02).
const Color segmentChosenInactive = Color(0xFF505051);
const Color bitText = Color(0xFF9E9E9E);
const Color bitLabel = Color(0xFFDEDEDE);
