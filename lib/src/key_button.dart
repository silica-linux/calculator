// A calculator key (calculator.md › Keys, States): a 48 pt circle or a capsule, with a 1 pt
// dark outline and a light rim (+44 levels on top, +30 at the bottom, +8 on the sides). No
// change on hover; pressed it lightens and fades back after the release (~200 ms, operators
// ~330 ms); a typed key lights it for ~80 ms. In an inactive window functions and operators
// turn gray.

import 'package:flutter/widgets.dart';

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

Color _lighter(Color c, int levels) {
  int ch(double v) => (v * 255 + levels).round().clamp(0, 255);
  return Color.fromARGB(255, ch(c.r), ch(c.g), ch(c.b));
}

/// A key's fill at rest: gray in an inactive window in every mode (orange too), `#7e7e7f`
/// for 2nd switched on (CA-01, CA-02).
Color keyFill(KeyRole role, {required bool active, bool toggled = false}) {
  final colors = keyColors[role] ?? keyColors[KeyRole.digit]!;
  if (!active) return colors.inactive;
  return toggled ? secondOn : colors.rest;
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

  /// The window is active (inactive: functions and operators gray).
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
  bool _down = false;
  int _flashSerial = 0;

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
    setState(() => _down = down);
    if (down) {
      _press.value = 1;
    } else {
      _press.reverse(from: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = keyColors[widget.role] ?? keyColors[KeyRole.digit]!;
    final rest = keyFill(
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
          return CustomPaint(
            key: ValueKey('key ${widget.id}'),
            size: Size(widget.width, keyHeight),
            painter: _KeyPainter(fill),
            child: SizedBox(
              width: widget.width,
              height: keyHeight,
              child: Center(child: widget.child(const Color(0xFFFFFFFF))),
            ),
          );
        },
      ),
    );
  }
}

class _KeyPainter extends CustomPainter {
  const _KeyPainter(this.fill);
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    final body = RRect.fromRectAndRadius(rect, radius);
    canvas
      ..drawRRect(body.inflate(1), Paint()..color = keyOutline)
      ..drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lighter(fill, 13), fill, fill, _lighter(fill, 7)],
            stops: const [0.02, 0.12, 0.88, 0.98],
          ).createShader(rect),
      )
      ..drawRRect(
        body.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _lighter(fill, 44),
              _lighter(fill, 8),
              _lighter(fill, 8),
              _lighter(fill, 30),
            ],
            stops: const [0, 0.3, 0.7, 1],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_KeyPainter old) => old.fill != fill;
}
