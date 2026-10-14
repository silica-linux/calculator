// The calculator window (calculator.md › Window and toolbar): always dark, fixed size per
// mode, toolbar 52 pt unified with the window (Ossido draws only the window buttons), two
// 36 pt circular buttons (history, mode), the display and the keypad. Typed keys light the
// matching key; the window goes gray when it is not the active one.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/app_localizations.dart';
import 'display.dart';
import 'engine/calculator.dart';
import 'engine/expression.dart';
import 'engine/format.dart';
import 'engine/programmer.dart';
import 'glyphs.dart';
import 'key_button.dart';
import 'keys.dart';
import 'metrics.dart';
import 'programmer_panel.dart';

/// Asks the embedder for the window size of a mode. False while Silica cannot resize a
/// window from the app (silica-desktop#1): the content then keeps the measured layout
/// anchored at the top-left corner.
Future<bool> requestWindowSize(Size size) async {
  try {
    final reply = await SilicaWindow.channel.invokeMethod<Object?>('setSize', {
      'width': size.width,
      'height': size.height,
    });
    return reply == true;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

class CalculatorWindow extends StatefulWidget {
  const CalculatorWindow({super.key, this.initialMode = CalcMode.basic});

  final CalcMode initialMode;

  @override
  State<CalculatorWindow> createState() => CalculatorWindowState();
}

class CalculatorWindowState extends State<CalculatorWindow> {
  late CalcMode mode = widget.initialMode;
  final DecimalCalculator decimal = DecimalCalculator();
  final ProgrammerCalculator programmer = ProgrammerCalculator();
  final KeyFlash _flash = KeyFlash();
  final FocusNode _focus = FocusNode();
  Offset? _menuAt;

  /// Shift held in the scientific mode shows the 2nd functions while it is down.
  bool _shiftSecond = false;

  bool _active = _isActive(WidgetsBinding.instance.lifecycleState);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      final active = _isActive(state);
      if (active != _active) setState(() => _active = active);
    },
  );

  static bool _isActive(AppLifecycleState? state) =>
      state == null || state == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _lifecycle;
    decimal.addListener(_changed);
    programmer.addListener(_changed);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    decimal.removeListener(_changed);
    programmer.removeListener(_changed);
    _focus.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  NumberStyle get _style =>
      NumberStyle.forLanguage(Localizations.localeOf(context).languageCode);

  void setMode(CalcMode next) {
    if (next == mode) return;
    // The mode switch is instant: size and keypad change in one frame (ca05-modes).
    setState(() {
      mode = next;
      _menuAt = null;
    });
    unawaited(requestWindowSize(windowSize[next]!));
  }

  List<List<KeySpec>> _keys(KeyTexts texts) => switch (mode) {
    CalcMode.basic => basicKeys(decimal, _style, texts),
    CalcMode.scientific => scientificKeys(decimal, _style, texts),
    CalcMode.programmer => programmerKeys(programmer, texts),
  };

  Future<void> copy() async {
    final text = mode == CalcMode.programmer
        ? programmer.copyText()
        : decimal.copyText(_style);
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null) return;
    if (mode == CalcMode.programmer) {
      programmer.paste(text);
    } else {
      decimal.paste(text, _style);
    }
  }

  /// The key a typed character stands for: its id and what it does.
  (String, VoidCallback)? _typed(KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return (
        'equals',
        mode == CalcMode.programmer ? programmer.equals : decimal.equals,
      );
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) {
      return (
        'clear',
        mode == CalcMode.programmer ? programmer.clear : decimal.clear,
      );
    }
    if (key == LogicalKeyboardKey.backspace) {
      return (
        'backspace',
        mode == CalcMode.programmer ? programmer.backspace : decimal.backspace,
      );
    }
    final ch = event.character;
    if (ch == null || ch.isEmpty) return null;
    if (mode == CalcMode.programmer) {
      final upper = ch.toUpperCase();
      if (programmer.acceptsDigit(upper)) {
        return ('digit $upper', () => programmer.digits(upper));
      }
      return switch (ch) {
        '+' => ('add', () => programmer.operator(ProgOp.add)),
        '-' => ('subtract', () => programmer.operator(ProgOp.subtract)),
        '*' || 'x' => ('multiply', () => programmer.operator(ProgOp.multiply)),
        '/' || ':' => ('divide', () => programmer.operator(ProgOp.divide)),
        '&' => ('and', () => programmer.operator(ProgOp.and)),
        '|' => ('or', () => programmer.operator(ProgOp.or)),
        '^' => ('xor', () => programmer.operator(ProgOp.xor)),
        '~' => ('not', () => programmer.unary(ProgUnary.not)),
        '%' => ('mod', () => programmer.operator(ProgOp.modulo)),
        '(' => ('open', programmer.open),
        ')' => ('close', programmer.close),
        '=' => ('equals', programmer.equals),
        _ => null,
      };
    }
    if (RegExp(r'^[0-9]$').hasMatch(ch)) return (ch, () => decimal.digit(ch));
    return switch (ch) {
      '.' || ',' => ('decimal', decimal.decimalPoint),
      '+' => ('add', () => decimal.operator(BinOp.add)),
      '-' => ('subtract', () => decimal.operator(BinOp.subtract)),
      '*' || 'x' => ('multiply', () => decimal.operator(BinOp.multiply)),
      '/' || ':' => ('divide', () => decimal.operator(BinOp.divide)),
      '%' => ('percent', () => decimal.postfix(Postfix.percent)),
      '=' => ('equals', decimal.equals),
      '^' when mode == CalcMode.scientific => (
        'power',
        () => decimal.operator(BinOp.power),
      ),
      '(' when mode == CalcMode.scientific => ('open', decimal.open),
      ')' when mode == CalcMode.scientific => ('close', decimal.close),
      '!' when mode == CalcMode.scientific => (
        'factorial',
        () => decimal.postfix(Postfix.factorial),
      ),
      _ => null,
    };
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final keys = HardwareKeyboard.instance;
    final shift =
        event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;
    if (shift && mode == CalcMode.scientific) {
      if (event is KeyDownEvent && !decimal.second) {
        _shiftSecond = true;
        decimal.toggleSecond();
      } else if (event is KeyUpEvent && _shiftSecond) {
        _shiftSecond = false;
        if (decimal.second) decimal.toggleSecond();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (keys.isMetaPressed || keys.isControlPressed) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.keyC) {
        unawaited(copy());
      } else if (key == LogicalKeyboardKey.keyV) {
        unawaited(paste());
      } else if (key == LogicalKeyboardKey.digit1) {
        setMode(CalcMode.basic);
      } else if (key == LogicalKeyboardKey.digit2) {
        setMode(CalcMode.scientific);
      } else if (key == LogicalKeyboardKey.digit3) {
        setMode(CalcMode.programmer);
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    final typed = _typed(event);
    if (typed == null) return KeyEventResult.ignored;
    typed.$2();
    _flash.flash(typed.$1);
    return KeyEventResult.handled;
  }

  List<MenuEntry> _modeMenu(AppLocalizations l) => [
    for (final (m, label, key) in [
      (CalcMode.basic, l.modeBasic, '1'),
      (CalcMode.scientific, l.modeScientific, '2'),
      (CalcMode.programmer, l.modeProgrammer, '3'),
    ])
      MenuAction(
        label,
        shortcut: '⌘$key',
        checked: m == mode,
        onSelected: () => setMode(m),
      ),
  ];

  Widget _toolbarButton({
    required Key key,
    required double left,
    required Glyph glyph,
    required String tooltip,
    bool hover = false,
    VoidCallback? onTap,
  }) => Positioned(
    left: left,
    top: toolbarButtonTop,
    width: toolbarButton,
    height: toolbarButton,
    child: ToolbarButton(
      key: key,
      glyph: glyph,
      tooltip: tooltip,
      active: _active,
      hover: hover,
      onTap: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = windowSize[mode]!;
    final texts = KeyTexts(
      clearAll: l.keyClearAll,
      clear: l.keyClear,
      secondTooltip: l.secondTooltip,
    );
    final rows = _keys(texts);
    final width = keyWidth[mode]!;
    final top = keypadTop[mode]!;
    final programmerMode = mode == CalcMode.programmer;
    final error = programmerMode ? programmer.error : decimal.error;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: ColoredBox(
        color: windowFill,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: ValueKey('calculator ${mode.name}'),
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: toolbarHeight,
                  child: WindowDragArea(child: SizedBox.expand()),
                ),
                if (!programmerMode)
                  _toolbarButton(
                    key: const ValueKey('history button'),
                    left: historyButtonLeft,
                    glyph: Glyph.sidebar,
                    tooltip: l.sidebarButton,
                  ),
                _toolbarButton(
                  key: const ValueKey('mode button'),
                  left: size.width - 44,
                  glyph: Glyph.calculator,
                  hover: true,
                  tooltip: l.modeButton,
                  // Under the button (ca09-mode-menu: left edge at the button, top at the
                  // toolbar's bottom). The reference menu extends past the window; ours stays
                  // inside it until menus are separate surfaces (silica-desktop#4).
                  onTap: () => setState(() {
                    final menu = menuSize(_modeMenu(l));
                    _menuAt = _menuAt != null
                        ? null
                        : Offset(
                            math.max(
                              4.0,
                              math.min(
                                size.width - 44,
                                size.width - menu.width - 4,
                              ),
                            ),
                            toolbarHeight,
                          );
                  }),
                ),
                Positioned(
                  left: keypadLeft,
                  right: displayRightPadding,
                  top: 0,
                  height: top,
                  child: Display(
                    main: error
                        ? l.error
                        : programmerMode
                        ? programmer.mainText()
                        : decimal.mainText(_style),
                    upper: programmerMode ? null : decimal.upperText(_style),
                    suffix: programmerMode && !error
                        ? '${programmer.base}'
                        : null,
                    indicator: programmerMode
                        ? programmer.character()
                        : mode == CalcMode.scientific &&
                              decimal.angle == AngleUnit.radians
                        ? l.radiansIndicator
                        : null,
                  ),
                ),
                if (programmerMode)
                  Positioned.fill(
                    child: ProgrammerPanel(
                      calc: programmer,
                      showBinaryLabel: l.showBinary,
                      hideBinaryLabel: l.hideBinary,
                      active: _active,
                    ),
                  ),
                for (var r = 0; r < rows.length; r++)
                  for (var c = 0; c < rows[r].length; c++)
                    Positioned(
                      left: programmerMode
                          ? programmerColumns[c]
                          : keypadLeft + c * columnPitch[mode]!,
                      top: top + r * rowPitch,
                      child: KeyButton(
                        id: rows[r][c].id,
                        role: rows[r][c].role,
                        width: width,
                        active: _active,
                        flash: _flash,
                        toggled: rows[r][c].toggled,
                        onPressed: rows[r][c].action,
                        child: rows[r][c].label,
                      ),
                    ),
                if (_menuAt != null)
                  Positioned.fill(
                    child: MenuHost(
                      entries: _modeMenu(l),
                      anchor: _menuAt!,
                      opaque: true,
                      onDismissed: () => setState(() => _menuAt = null),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 36 pt circular toolbar button: `#444546` with a 1 pt `#0f0f0f` outline, `#3b3b3c` in an
/// inactive window. Only the Mode button lightens under the pointer (`#4e4e4f`, CA-02).
class ToolbarButton extends StatefulWidget {
  const ToolbarButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.active,
    this.hover = false,
    this.onTap,
  });

  final Glyph glyph;
  final String tooltip;
  final bool active;

  /// Has the hover state (the Mode button).
  final bool hover;
  final VoidCallback? onTap;

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _over = false;

  Color get fill => !widget.active
      ? toolbarButtonInactive
      : widget.hover && _over
      ? toolbarButtonHover
      : toolbarButtonFill;

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.tooltip,
    button: true,
    child: MouseRegion(
      onEnter: (_) => setState(() => _over = true),
      onExit: (_) => setState(() => _over = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: toolbarButtonOutline),
          ),
          child: Center(
            child: GlyphIcon(widget.glyph, color: const Color(0xFFFFFFFF)),
          ),
        ),
      ),
    ),
  );
}
