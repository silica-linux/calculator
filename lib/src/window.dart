// The calculator window (kit `App · Calculator`, calculator.md › Window and toolbar): always
// dark, fixed size per mode, toolbar 52 pt unified with the window (the compositor draws the
// window buttons), the Mode button, the display and the keypad. Typed keys light the matching
// key; the window goes gray when it is not the active one.

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
import 'history.dart';
import 'key_button.dart';
import 'keys.dart';
import 'metrics.dart';
import 'programmer_panel.dart';

/// Fixes the window to the size of a mode (fixed sizes per mode, calculator.md): the limits
/// and the size together, so the window cannot be resized and the zoom button is disabled.
Future<bool> requestWindowSize(Size size) => SilicaWindow.setFixedSize(size);

class CalculatorWindow extends StatefulWidget {
  const CalculatorWindow({
    super.key,
    this.initialMode = CalcMode.basic,
    this.history,
  });

  final CalcMode initialMode;

  /// The records of the calculations; null keeps them in memory only (tests).
  final HistoryStore? history;

  @override
  State<CalculatorWindow> createState() => CalculatorWindowState();
}

class CalculatorWindowState extends State<CalculatorWindow> {
  late CalcMode mode = widget.initialMode;
  final DecimalCalculator decimal = DecimalCalculator();
  final ProgrammerCalculator programmer = ProgrammerCalculator();
  final KeyFlash _flash = KeyFlash();
  final FocusNode _focus = FocusNode();

  /// Shift held in the scientific mode shows the 2nd functions while it is down.
  bool _shiftSecond = false;

  late final HistoryStore history = widget.history ?? HistoryStore();

  /// The history sidebar is open (⌃⌘S): the window is 220 pt wider and the display and the
  /// keypad shift right. Not in the programmer mode, which has no history.
  bool showHistory = false;
  bool _wasEvaluated = false;

  /// The wall clock: the history groups the records by day.
  DateTime _now() => DateTime.now();

  /// View › Hide Thousands Separators: results and entries without digit grouping.
  bool thousands = true;

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
    unawaited(requestWindowSize(windowSize[widget.initialMode]!));
    _wasEvaluated = decimal.evaluated;
    decimal.addListener(_decimalChanged);
    programmer.addListener(_changed);
    history.addListener(_changed);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    decimal.removeListener(_decimalChanged);
    programmer.removeListener(_changed);
    history.removeListener(_changed);
    _focus.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  /// A result ("=") goes into the history, once.
  void _decimalChanged() {
    if (decimal.evaluated && !_wasEvaluated) {
      history.add(
        renderTokens(decimal.previous, _style),
        formatNumber(decimal.result, _style, places: decimal.places),
        _now(),
      );
    }
    _wasEvaluated = decimal.evaluated;
    _changed();
  }

  /// The window of [m] with or without the history sidebar.
  Size _sizeOf(CalcMode m, bool history) {
    final base = windowSize[m]!;
    return history && m != CalcMode.programmer
        ? Size(base.width + HistoryMetrics.width, base.height)
        : base;
  }

  /// View › Show / Hide History (⌃⌘S) and the toolbar button.
  void toggleHistory() {
    if (mode == CalcMode.programmer) return;
    setState(() => showHistory = !showHistory);
    unawaited(requestWindowSize(_sizeOf(mode, showHistory)));
  }

  NumberStyle get _style {
    final style = NumberStyle.forLanguage(
      Localizations.localeOf(context).languageCode,
    );
    return thousands ? style : NumberStyle(decimal: style.decimal, group: '');
  }

  /// View › Hide / Show Thousands Separators (`calculator.thousands`).
  void toggleThousands() => setState(() => thousands = !thousands);

  /// View › Decimal Places (`calculator.decimal_places`).
  void setPlaces(int places) => decimal.setPlaces(places);

  void setMode(CalcMode next) {
    if (next == mode) return;
    // The mode switch is instant: size and keypad change in one frame (silica-reference CA-01).
    setState(() => mode = next);
    unawaited(requestWindowSize(_sizeOf(next, showHistory)));
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
    // ⌘ shortcuts are the menu bar's (SilicaMenuBar binds them); Ctrl stays an alternative.
    if (keys.isMetaPressed) return KeyEventResult.ignored;
    if (keys.isControlPressed) {
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

  /// The menus in Silica's menu bar (silica-desktop#25; calculator.md › Menus): the app menu,
  /// Edit with Copy and Paste (the others disabled, as on the reference), View with the
  /// modes, the thousands separators and the decimal places, Window with Close, Help.
  List<PlatformMenuItem> menus(AppLocalizations l) {
    final decimals = mode != CalcMode.programmer;
    return [
      SilicaMenus.app(l.appTitle),
      SilicaMenus.edit(
        l.menuEdit,
        copy: () => unawaited(copy()),
        paste: () => unawaited(paste()),
      ),
      SilicaMenu(
        label: l.menuView,
        menus: [
          PlatformMenuItemGroup(
            members: [
              for (final (m, label, key) in [
                (CalcMode.basic, l.modeBasic, LogicalKeyboardKey.digit1),
                (
                  CalcMode.scientific,
                  l.modeScientific,
                  LogicalKeyboardKey.digit2,
                ),
                (
                  CalcMode.programmer,
                  l.modeProgrammer,
                  LogicalKeyboardKey.digit3,
                ),
              ])
                SilicaMenuItem(
                  label: label,
                  checked: m == mode,
                  shortcut: SingleActivator(key, meta: true),
                  onSelected: () => setMode(m),
                ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              SilicaMenuItem(
                label: thousands ? l.hideThousands : l.showThousands,
                enabled: decimals,
                onSelected: toggleThousands,
              ),
              SilicaMenu(
                label: l.decimalPlaces,
                enabled: decimals,
                menus: [
                  for (var p = 0; p <= maxPlaces; p++)
                    SilicaMenuItem(
                      label: '$p',
                      checked: decimal.places == p,
                      onSelected: () => setPlaces(p),
                    ),
                ],
              ),
            ],
          ),
          // A fixed-size window has no full screen (CA-01: the item is disabled).
          PlatformMenuItemGroup(
            members: [
              SilicaMenuItem(
                label: showHistory && decimals ? l.hideHistory : l.showHistory,
                enabled: decimals,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  control: true,
                  meta: true,
                ),
                onSelected: toggleHistory,
              ),
              const SilicaMenuItem.system(
                SilicaMenuItemRole.fullScreen,
                enabled: false,
              ),
            ],
          ),
        ],
      ),
      SilicaMenus.window(l.menuWindow, close: true),
      SilicaMenus.help(l.menuHelp),
    ];
  }

  List<AmalfiMenuEntry> _modeMenu(AppLocalizations l) => [
    for (final (m, label, key) in [
      (CalcMode.basic, l.modeBasic, '1'),
      (CalcMode.scientific, l.modeScientific, '2'),
      (CalcMode.programmer, l.modeProgrammer, '3'),
    ])
      AmalfiMenuAction(
        label,
        shortcut: '⌘$key',
        checked: m == mode,
        onSelected: () => setMode(m),
      ),
  ];

  /// The Mode button's menu, below the button and ending with it (Escape or a click outside
  /// closes it).
  void _openModeMenu(BuildContext button, AppLocalizations l) {
    final box = button.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    const width = 200.0;
    final topLeft = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(button);
    final x = math.max(
      4.0,
      math.min(topLeft.dx + box.size.width - width, screen.width - width - 4),
    );
    unawaited(
      showAmalfiMenu(
        context: button,
        position: Offset(x, topLeft.dy + box.size.height + 4),
        entries: _modeMenu(l),
        width: width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = AmalfiTheme.of(context);
    final size = _sizeOf(mode, showHistory);
    final texts = KeyTexts(
      clearAll: l.keyClearAll,
      clear: l.keyClear,
      secondTooltip: l.secondTooltip,
    );
    final rows = _keys(texts);
    final width = keyWidth[mode]!;
    final top = keypadTop[mode]!;
    final programmerMode = mode == CalcMode.programmer;
    final sidebar = showHistory && !programmerMode;
    final dx = sidebar ? HistoryMetrics.width : 0.0;
    final error = programmerMode ? programmer.error : decimal.error;
    return SilicaMenuBar(
      menus: menus(l),
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: ValueKey('calculator ${mode.name}'),
            width: size.width,
            height: size.height,
            // A real toplevel: the compositor draws the shadow (`shadow: false`).
            child: AmalfiWindow(
              active: _active,
              shadow: false,
              child: ColoredBox(
                color: theme.colors.calculator.window,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: AmalfiToolbarMetrics.toolbarHeight,
                      child: WindowDragArea(child: SizedBox.expand()),
                    ),
                    // Kit `Toolbar Basic|Sci|Prog`: the controls piece (the compositor draws
                    // the window buttons there), the History toggle (not in the programmer
                    // mode), a spacer and the Mode button.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: AmalfiToolbar(
                        surface: AmalfiToolbarSurface.none,
                        padding: const EdgeInsets.only(right: 8),
                        active: _active,
                        children: [
                          const SizedBox(width: controlsWidth),
                          if (!programmerMode)
                            AmalfiToolbarPiece(
                              child: AmalfiToolbarButton(
                                key: const ValueKey('history button'),
                                semanticLabel: l.sidebarButton,
                                icon: const AmalfiSymbol('sidebar'),
                                onPressed: toggleHistory,
                              ),
                            ),
                          const AmalfiSpacerPiece(),
                          AmalfiToolbarPiece(
                            child: Builder(
                              builder: (button) => AmalfiToolbarButton(
                                key: const ValueKey('mode button'),
                                semanticLabel: l.modeButton,
                                icon: const AmalfiSymbol('ellipsis'),
                                onPressed: () => _openModeMenu(button, l),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sidebar) ...[
                      Positioned(
                        left: 0,
                        top: AmalfiToolbarMetrics.toolbarHeight,
                        bottom: 0,
                        width: HistoryMetrics.width,
                        child: HistorySidebar(store: history, now: _now),
                      ),
                      Positioned(
                        left: HistoryMetrics.width,
                        top: AmalfiToolbarMetrics.toolbarHeight,
                        bottom: 0,
                        width: 1,
                        child: ColoredBox(
                          color: AmalfiTheme.of(context).colors.lineSeparator,
                        ),
                      ),
                    ],
                    Positioned(
                      left: displayPadding + dx,
                      right: displayPadding,
                      top: 0,
                      height: top,
                      child: Display(
                        main: error
                            ? l.error
                            : programmerMode
                            ? programmer.mainText()
                            : decimal.mainText(_style),
                        upper: programmerMode
                            ? null
                            : decimal.upperText(_style),
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
                        ),
                      ),
                    for (var r = 0; r < rows.length; r++)
                      for (var c = 0; c < rows[r].length; c++)
                        Positioned(
                          left: keypadLeft + dx + c * columnPitch(mode),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
