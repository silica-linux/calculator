// A calculator key (kit `Apps/Calculator/Key/*`, calculator.md › Keys, States): a flat 48 pt
// circle or capsule from the palette. No change on hover; pressed it lightens and fades back
// after the release (~200 ms, operators ~330 ms); a typed key lights it for ~80 ms. In an
// inactive window keys turn gray.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'metrics.dart';

/// Which key the keyboard just pressed (its id), to light it.
class KeyFlash extends ChangeNotifier {
  String? id;
  int serial = 0;

  void flash(String key) {
    id = key;
    serial++;
    notifyListeners();
  }
}

/// A key's fill at rest, from the `App/Calculator` palette: gray in an inactive window in every
/// mode (orange too), `#7e7e7f` for 2nd switched on (CA-01, CA-02).
Color keyFill(
  AmalfiCalculatorColors palette,
  KeyRole role, {
  required bool active,
  bool toggled = false,
}) {
  final colors = keyColors[role]!;
  if (!active) return colors.inactive;
  if (toggled) return secondOn;
  return switch (role) {
    KeyRole.digit => palette.digit,
    KeyRole.function => palette.function,
    KeyRole.operator => palette.operator,
    KeyRole.scientific || KeyRole.programmer => palette.scientific,
  };
}

class KeyButton extends StatefulWidget {
  const KeyButton({
    super.key,
    required this.id,
    required this.role,
    required this.width,
    required this.child,
    required this.onPressed,
    required this.active,
    required this.flash,
    this.toggled = false,
  });

  final String id;
  final KeyRole role;
  final double width;

  /// The glyph or label, built for the glyph colour.
  final Widget Function(Color color) child;
  final VoidCallback onPressed;

  /// The window is active (inactive: keys gray).
  final bool active;
  final KeyFlash flash;

  /// 2nd switched on.
  final bool toggled;

  @override
  State<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<KeyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: widget.role == KeyRole.operator ? fadeOperator : fadeDigit,
  );
  int _flashSerial = 0;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    widget.flash.addListener(_onFlash);
  }

  @override
  void didUpdateWidget(KeyButton old) {
    super.didUpdateWidget(old);
    if (old.flash != widget.flash) {
      old.flash.removeListener(_onFlash);
      widget.flash.addListener(_onFlash);
    }
  }

  @override
  void dispose() {
    widget.flash.removeListener(_onFlash);
    _press.dispose();
    super.dispose();
  }

  void _onFlash() {
    final f = widget.flash;
    if (f.id != widget.id || f.serial == _flashSerial) return;
    _flashSerial = f.serial;
    // Lit for two frames, no fade.
    _press.value = 1;
    Future<void>.delayed(keyboardFlash, () {
      if (mounted && !_down) _press.value = 0;
    });
  }

  void _setDown(bool down) {
    _down = down;
    if (down) {
      _press.value = 1;
    } else {
      _press.reverse(from: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = keyColors[widget.role]!;
    final rest = keyFill(
      theme.colors.calculator,
      widget.role,
      active: widget.active,
      toggled: widget.toggled,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) {
        _setDown(false);
        widget.onPressed();
      },
      onTapCancel: () => _setDown(false),
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, _) {
          final fill = Color.lerp(rest, colors.pressed, _press.value) ?? rest;
          return DecoratedBox(
            key: ValueKey('key ${widget.id}'),
            // Kit `Key/*`: a flat capsule (a circle at 48 × 48) with smooth corners.
            decoration: AmalfiShapeDecoration(
              color: fill,
              shape: AmalfiSmoothBorder(radius: keyHeight / 2),
            ),
            child: SizedBox(
              width: widget.width,
              height: keyHeight,
              child: Center(child: widget.child(theme.colors.textOnAccent)),
            ),
          );
        },
      ),
    );
  }
}
