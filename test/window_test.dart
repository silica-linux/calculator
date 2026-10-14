import 'package:calculator/main.dart';
import 'package:calculator/src/metrics.dart';
import 'package:calculator/src/key_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('basic keypad geometry (CA-01)', (tester) async {
    await pump(tester);
    // Circles of 48 at a 54 pt pitch, 10 pt from the left, first row at y 133.
    expect(
      tester.getRect(key('backspace')),
      const Rect.fromLTWH(10, 133, 48, 48),
    );
    expect(
      tester.getRect(key('divide')),
      const Rect.fromLTWH(172, 133, 48, 48),
    );
    expect(
      tester.getRect(key('equals')),
      const Rect.fromLTWH(172, 349, 48, 48),
    );
    // 349 + 48 + 11 = 408, the window height.
    expect(
      tester.getRect(key('0')).bottom + 11,
      windowSize[CalcMode.basic]!.height,
    );
    // The two toolbar buttons: 36 pt circles at x 96 and 186.
    expect(
      tester.getRect(find.byKey(const ValueKey('history button'))),
      const Rect.fromLTWH(96, 8, 36, 36),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('mode button'))),
      const Rect.fromLTWH(186, 8, 36, 36),
    );
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
    // Scientific: capsules 60 × 48 at a 66 pt pitch; the mode button at width − 44.
    expect(tester.getRect(key('open')), const Rect.fromLTWH(10, 133, 60, 48));
    expect(
      tester.getRect(key('divide')),
      const Rect.fromLTWH(604, 133, 60, 48),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('mode button'))).left,
      674 - 44,
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
    // Programmer: 62 × 48 at the measured columns, first row at y 254; no history button.
    expect(
      tester.getRect(key('backspace')),
      const Rect.fromLTWH(10, 254, 62, 48),
    );
    expect(
      tester.getRect(key('equals')),
      const Rect.fromLTWH(416, 524, 62, 48),
    );
    expect(find.byKey(const ValueKey('history button')), findsNothing);
    await tap(tester, 'digit F');
    await tap(tester, 'digit F');
    expect(mainLine(tester), 'FF');
    await tester.tap(find.byKey(const ValueKey('base 10')));
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
    expect(keyFill(KeyRole.operator, active: true), const Color(0xFFFF8B00));
    expect(keyFill(KeyRole.operator, active: false), const Color(0xFF545555));
    expect(keyFill(KeyRole.function, active: false), const Color(0xFF545555));
    expect(keyFill(KeyRole.scientific, active: false), const Color(0xFF474749));
    expect(keyFill(KeyRole.programmer, active: false), const Color(0xFF474749));
    expect(keyFill(KeyRole.digit, active: false), const Color(0xFF4D4D4E));
    expect(
      keyFill(KeyRole.scientific, active: true, toggled: true),
      const Color(0xFF7E7E7F),
    );
  });

  testWidgets('inactive: base segment and toolbar buttons gray; Mode hover', (
    tester,
  ) async {
    await pump(tester);
    Color? fillOf(Finder f) =>
        (tester
                    .widgetList<DecoratedBox>(
                      find.descendant(
                        of: f,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .first
                    .decoration
                as BoxDecoration)
            .color;
    final mode = find.byKey(const ValueKey('mode button'));
    expect(fillOf(mode), toolbarButtonFill);
    // Only the Mode button has a hover state.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(mode));
    await tester.pump();
    expect(fillOf(mode), toolbarButtonHover);
    final history = find.byKey(const ValueKey('history button'));
    await mouse.moveTo(tester.getCenter(history));
    await tester.pump();
    expect(fillOf(history), toolbarButtonFill);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    // The chosen segment's fill (the Container inside the tappable segment).
    Color? segment() =>
        (tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byKey(const ValueKey('base 16')),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration?)
            ?.color;
    expect(segment(), segmentChosen);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(segment(), segmentChosenInactive);
    expect(fillOf(mode), toolbarButtonInactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });
}
