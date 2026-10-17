import 'package:calculator/main.dart';
import 'package:calculator/src/metrics.dart';
import 'package:calculator/src/key_button.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart' show AmalfiCalculatorColors;

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(674, 582),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CalculatorApp(locale: locale));
    await tester.pump();
  }

  Finder key(String id) => find.byKey(ValueKey('key $id'));

  String mainLine(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('main line')),
          matching: find.byType(Text),
        ),
      )
      .first
      .data!;

  Future<void> tap(WidgetTester tester, String id) async {
    await tester.tap(key(id));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('basic geometry on the kit master Apps/Calculator/Basic', (
    tester,
  ) async {
    await pump(tester);
    // Master 248 × 412: circles of 48 at a 56 pt pitch, padding 16, first row at y 124.
    expect(
      tester.getRect(find.byKey(const ValueKey('calculator basic'))),
      const Rect.fromLTWH(0, 0, 248, 412),
    );
    expect(
      tester.getRect(key('backspace')),
      const Rect.fromLTWH(16, 124, 48, 48),
    );
    expect(
      tester.getRect(key('divide')),
      const Rect.fromLTWH(184, 124, 48, 48),
    );
    expect(
      tester.getRect(key('equals')),
      const Rect.fromLTWH(184, 348, 48, 48),
    );
    expect(tester.getRect(key('0')), const Rect.fromLTWH(72, 348, 48, 48));
    // 348 + 48 + 16 = 412, the window height.
    expect(
      tester.getRect(key('0')).bottom + 16,
      windowSize[CalcMode.basic]!.height,
    );
    // Display: 216 × 40 at (16, 68), Inter Bold 34 / 40.
    expect(
      tester.getRect(find.byKey(const ValueKey('main line'))),
      const Rect.fromLTWH(16, 68, 216, 40),
    );
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('main line')),
        matching: find.byType(Text),
      ),
    );
    expect(text.style!.fontSize, 34);
    expect(text.style!.fontWeight, FontWeight.w700);
    // Toolbar: the Mode button is a 32 pt circle in a 40 pt piece, 8 from the edge
    // (master Toolbar Basic: More at x 200).
    expect(
      tester.getRect(find.byKey(const ValueKey('mode button'))),
      const Rect.fromLTWH(204, 10, 32, 32),
    );
    // Kit `Toolbar History`: the sidebar toggle is a 40 pt piece at x 96.
    expect(
      tester.getRect(find.byKey(const ValueKey('history button'))),
      const Rect.fromLTWH(100, 10, 32, 32),
    );
  });

  testWidgets(
    'the history sidebar: +220 pt, records by period, Copy and Delete',
    (tester) async {
      await pump(tester);
      for (final id in ['1', '2', 'add', '3', '4', 'equals']) {
        await tap(tester, id);
      }
      await tester.tap(find.byKey(const ValueKey('history button')));
      await tester.pump(const Duration(milliseconds: 300));
      // Kit master Apps/Calculator/History: 468 × 412, the keypad shifted by 220.
      expect(
        tester.getSize(find.byKey(const ValueKey('calculator basic'))),
        const Size(468, 412),
      );
      expect(tester.getRect(key('0')).left, 72 + 220);
      expect(
        tester.getRect(find.byKey(const ValueKey('main line'))),
        const Rect.fromLTWH(236, 68, 216, 40),
      );
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('12+34'), findsWidgets);
      final result = find.descendant(
        of: find.byKey(const ValueKey('history list')),
        matching: find.text('46'),
      );
      expect(result, findsOneWidget);
      // The kit: header at y 60, expression at 104, result at 124.
      expect(tester.getTopLeft(find.text('Today')).dy, closeTo(60, 3));
      // A second calculation is listed above the first.
      await tap(tester, 'clear');
      for (final id in ['8', 'multiply', '7', 'equals']) {
        await tap(tester, id);
      }
      final first = tester.getTopLeft(
        find.descendant(
          of: find.byKey(const ValueKey('history list')),
          matching: find.text('56'),
        ),
      );
      expect(first.dy, lessThan(tester.getTopLeft(result).dy));
      // Delete from the context menu.
      await tester.tap(result, buttons: kSecondaryButton);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Copy'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(result, findsNothing);
      // Closing it gives the window back.
      await tester.tap(find.byKey(const ValueKey('history button')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.getSize(find.byKey(const ValueKey('calculator basic'))),
        const Size(248, 412),
      );
    },
  );

  testWidgets('keys are flat capsules from the App/Calculator palette', (
    tester,
  ) async {
    await pump(tester);
    Color fill(String id) {
      final box = tester.widget<DecoratedBox>(key(id));
      return (box.decoration as ShapeDecoration).color!;
    }

    expect(fill('7'), const Color(0xFF6A6A6B));
    expect(fill('clear'), const Color(0xFF919191));
    expect(fill('divide'), const Color(0xFFFF8B00));
  });

  testWidgets('the Mode button opens the mode menu and Escape closes it', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('mode button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Scientific'), findsOneWidget);
    await tester.tap(find.text('Programmer'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('calculator programmer')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mode button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Basic'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Basic'), findsNothing);
  });

  testWidgets('typing on the keys: inline expression, = moves it up', (
    tester,
  ) async {
    await pump(tester);
    expect(mainLine(tester), '0');
    expect(find.text('AC'), findsOneWidget);
    for (final id in ['1', '2', 'add', '3', '4']) {
      await tap(tester, id);
    }
    expect(mainLine(tester), '12+34');
    expect(find.text('C'), findsOneWidget);
    await tap(tester, 'equals');
    expect(mainLine(tester), '46');
    expect(find.text('12+34'), findsOneWidget);
    expect(find.byKey(const ValueKey('expression line')), findsOneWidget);
  });

  testWidgets('the keyboard types and lights the matching key', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal, character: '+');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(mainLine(tester), '12');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 100));
    expect(mainLine(tester), '0');
  });

  testWidgets('modes: instant switch with the measured keypads (⌘2, ⌘3, ⌘1)', (
    tester,
  ) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    // Master Scientific 664 × 412: capsules 56 × 48 at a 64 pt pitch; the Mode button ends
    // the bar.
    expect(
      tester.getRect(find.byKey(const ValueKey('calculator scientific'))),
      const Rect.fromLTWH(0, 0, 664, 412),
    );
    expect(tester.getRect(key('open')), const Rect.fromLTWH(16, 124, 56, 48));
    expect(tester.getRect(key('mr')), const Rect.fromLTWH(336, 124, 56, 48));
    expect(
      tester.getRect(key('backspace')),
      const Rect.fromLTWH(400, 124, 56, 48),
    );
    expect(
      tester.getRect(key('divide')),
      const Rect.fromLTWH(592, 124, 56, 48),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('mode button'))).right,
      664 - 12,
    );
    await tap(tester, '3');
    await tap(tester, '0');
    await tap(tester, 'sin');
    expect(mainLine(tester), 'sin(30)');
    await tap(tester, 'equals');
    expect(mainLine(tester), '0.5');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    // Master Programmer 528 × 576: capsules 64 × 48 at a 72 pt pitch, first row at y 232.
    expect(
      tester.getRect(find.byKey(const ValueKey('calculator programmer'))),
      const Rect.fromLTWH(0, 0, 528, 576),
    );
    expect(
      tester.getRect(key('backspace')),
      const Rect.fromLTWH(16, 232, 64, 48),
    );
    expect(
      tester.getRect(key('equals')),
      const Rect.fromLTWH(448, 512, 64, 48),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('bit editor'))),
      const Rect.fromLTWH(16, 160, 496, 64),
    );
    final encoding = tester.getRect(find.byKey(const ValueKey('encoding')));
    expect(encoding.topLeft, const Offset(16, 128));
    expect(encoding.height, 24);
    expect(tester.getRect(find.byKey(const ValueKey('binary'))).top, 128);
    final base = tester.getRect(find.byKey(const ValueKey('base')));
    expect(base.right, 516);
    expect(base.height, 24);
    expect(find.byKey(const ValueKey('history button')), findsNothing);
    await tap(tester, 'digit F');
    await tap(tester, 'digit F');
    expect(mainLine(tester), 'FF');
    await tester.tapAt(
      tester.getRect(find.byKey(const ValueKey('base'))).center,
    );
    await tester.pump();
    expect(mainLine(tester), '255');
    await tester.tap(find.byKey(const ValueKey('bit 8')));
    await tester.pump();
    expect(mainLine(tester), '511');
  });

  testWidgets('Italian: comma decimal key and translated texts', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('it'));
    expect(
      find.descendant(of: key('decimal'), matching: find.text(',')),
      findsOneWidget,
    );
    for (final id in ['1', 'decimal', '5', 'multiply', '2', 'equals']) {
      await tap(tester, id);
    }
    expect(mainLine(tester), '3');
    for (final id in ['1', 'divide', '0', 'equals']) {
      await tap(tester, id);
    }
    expect(mainLine(tester), 'Errore');
  });

  testWidgets('the window state follows flutter/lifecycle', (tester) async {
    await pump(tester);
    bool active() => tester
        .widget<KeyButton>(
          find.ancestor(of: key('add'), matching: find.byType(KeyButton)),
        )
        .active;
    expect(active(), isTrue);
    // Inactive: functions and operators turn gray (silica-reference CA-01).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(active(), isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(active(), isTrue);
  });

  test('inactive fills in every mode (CA-02)', () {
    const palette = AmalfiCalculatorColors.dark;
    Color fill(KeyRole role, {bool active = true, bool toggled = false}) =>
        keyFill(palette, role, active: active, toggled: toggled);
    expect(fill(KeyRole.operator), const Color(0xFFFF8B00));
    expect(fill(KeyRole.operator, active: false), const Color(0xFF545555));
    expect(fill(KeyRole.function, active: false), const Color(0xFF545555));
    expect(fill(KeyRole.scientific, active: false), const Color(0xFF474749));
    expect(fill(KeyRole.programmer, active: false), const Color(0xFF474749));
    expect(fill(KeyRole.digit, active: false), const Color(0xFF4D4D4E));
    expect(fill(KeyRole.scientific, toggled: true), const Color(0xFF7E7E7F));
  });

  testWidgets('the toolbar, the display and the background are drag areas', (
    tester,
  ) async {
    await pump(tester);
    for (final k in ['toolbar', 'display', 'window']) {
      expect(find.byKey(ValueKey('$k drag area')), findsOneWidget);
    }
    // The toolbar strip is covered by the toolbar's drag area, not only the background.
    final bar = tester.getRect(find.byKey(const ValueKey('toolbar drag area')));
    expect(bar.top, 0);
    expect(bar.height, greaterThanOrEqualTo(52));
    // The Mode button stays a button inside it.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('toolbar drag area')),
        matching: find.byKey(const ValueKey('mode button')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the history sidebar keeps a drag area', (tester) async {
    await pump(tester, size: const Size(900, 600));
    await tester.tap(find.byKey(const ValueKey('history button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('history drag area')), findsOneWidget);
  });
}
