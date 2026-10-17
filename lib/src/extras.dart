// The displays of Convert and RPN (kit `Apps/Calculator/Convert`, `RPN`), the stack keys and
// the unit picker popover (kit `Apps/Calculator/Unit Picker`).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/app_localizations.dart';
import 'display.dart';
import 'engine/units.dart';
import 'metrics.dart';

TextStyle _tabular(TextStyle style) =>
    style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// The two lines of Convert, in window coordinates (the box starts at the window's top): the
/// from unit and its value at y 60, the swap button under the unit, the to unit and the
/// converted value at y 108 (values 176 pt wide, 32 pt high; unit codes 16 pt from the edge).
class ConvertDisplay extends StatelessWidget {
  const ConvertDisplay({
    super.key,
    required this.from,
    required this.to,
    required this.fromText,
    required this.toText,
    required this.onFromUnit,
    required this.onToUnit,
    required this.onSwap,
  });

  final ConvertUnit from;
  final ConvertUnit to;
  final String fromText;
  final String toText;
  final void Function(Rect anchor) onFromUnit;
  final void Function(Rect anchor) onToUnit;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final secondary = colors.calculator.displaySecondary;
    final style = _tabular(
      AmalfiType.display(color: colors.textPrimary).copyWith(fontSize: 28),
    );
    return Stack(
      children: [
        Positioned(
          left: 40,
          right: 0,
          top: 60,
          height: 32,
          child: DisplayLine(
            key: const ValueKey('convert from value'),
            text: fromText,
            style: style,
            small: 18,
            height: 32,
          ),
        ),
        Positioned(
          left: 40,
          right: 0,
          top: 108,
          height: 32,
          child: DisplayLine(
            key: const ValueKey('convert to value'),
            text: toText,
            style: style.copyWith(color: secondary),
            small: 18,
            height: 32,
          ),
        ),
        Positioned(
          left: 0,
          top: 58,
          child: _UnitButton(
            key: const ValueKey('from unit'),
            unit: from,
            semanticLabel: l.fromUnit,
            onPressed: onFromUnit,
          ),
        ),
        Positioned(
          left: 0,
          top: 106,
          child: _UnitButton(
            key: const ValueKey('to unit'),
            unit: to,
            semanticLabel: l.toUnit,
            onPressed: onToUnit,
          ),
        ),
        Positioned(
          left: -4,
          top: 80,
          width: 28,
          height: 28,
          child: AmalfiTooltipRegion(
            message: l.swapUnits,
            child: GestureDetector(
              key: const ValueKey('swap units'),
              behavior: HitTestBehavior.opaque,
              onTap: onSwap,
              child: Center(
                child: AmalfiSymbol(
                  'arrow-up-down',
                  size: 20,
                  color: colors.calculator.operator,
                  fallback: Text(
                    '⇅',
                    style: AmalfiType.title2(color: colors.calculator.operator),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The unit pop-up: the code and the up-down chevron (Caption, secondary).
class _UnitButton extends StatelessWidget {
  const _UnitButton({
    super.key,
    required this.unit,
    required this.semanticLabel,
    required this.onPressed,
  });

  final ConvertUnit unit;
  final String semanticLabel;
  final void Function(Rect anchor) onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final secondary = colors.calculator.displaySecondary;
    return Semantics(
      button: true,
      label: '$semanticLabel: ${unit.symbol}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final box = context.findRenderObject();
          if (box is! RenderBox || !box.hasSize) return;
          onPressed(box.localToGlobal(Offset.zero) & box.size);
        },
        child: SizedBox(
          height: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unit.symbol,
                maxLines: 1,
                style: AmalfiType.caption(color: secondary),
              ),
              const SizedBox(width: 2),
              AmalfiSymbol(
                'chevron-up-down',
                size: 12,
                color: secondary,
                fallback: Text(
                  '⌃',
                  style: AmalfiType.caption(color: secondary),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// The stack of RPN, in window coordinates: t, z, y, x at y 56, 92, 128, 164 (26 pt high, 36
/// apart) with their labels at the left, 1 pt separators under each and the four stack keys
/// at y 204.
class RpnDisplay extends StatelessWidget {
  const RpnDisplay({
    super.key,
    required this.lines,
    required this.onSwap,
    required this.onRollDown,
    required this.onRollUp,
    required this.onDrop,
  });

  /// x, y, z, t (index 0 is x).
  final List<String> lines;
  final VoidCallback onSwap;
  final VoidCallback onRollDown;
  final VoidCallback onRollUp;
  final VoidCallback onDrop;

  static const _labels = ['t', 'z', 'y', 'x'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final secondary = colors.calculator.displaySecondary;
    final style = _tabular(
      AmalfiType.display(color: colors.textPrimary).copyWith(fontSize: 22),
    );
    return Stack(
      children: [
        for (var row = 0; row < 4; row++) ...[
          // Row 0 is t: the stack's last element.
          Positioned(
            left: 0,
            right: 0,
            top: 56 + row * 36.0,
            height: 26,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    _labels[row],
                    key: ValueKey('register ${_labels[row]}'),
                    style: AmalfiType.caption(color: secondary),
                  ),
                ),
                Expanded(
                  child: DisplayLine(
                    key: ValueKey('stack ${_labels[row]}'),
                    text: lines[3 - row],
                    style: row == 3
                        ? style
                        : style.copyWith(color: colors.textSecondary),
                    small: 15,
                    height: 26,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 88 + row * 36.0,
            height: 1,
            child: ColoredBox(color: colors.lineSeparator),
          ),
        ],
        Positioned(
          left: 0,
          right: 0,
          top: 204,
          height: 28,
          child: Row(
            spacing: 8,
            children: [
              for (final (id, label, tip, action) in [
                ('swap', 'x⇄y', l.stackSwap, onSwap),
                ('rolldown', 'R↓', l.stackRollDown, onRollDown),
                ('rollup', 'R↑', l.stackRollUp, onRollUp),
                ('drop', l.stackDrop, l.stackDropTip, onDrop),
              ])
                Expanded(
                  child: StackKey(
                    id: id,
                    label: label,
                    tooltip: tip,
                    onPressed: action,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A stack key: a 48 × 28 capsule in the function fill, lighter while pressed.
class StackKey extends StatefulWidget {
  const StackKey({
    super.key,
    required this.id,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String id;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<StackKey> createState() => _StackKeyState();
}

class _StackKeyState extends State<StackKey> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final fill = _down
        ? keyColors[KeyRole.function]!.pressed
        : colors.calculator.function;
    return AmalfiTooltipRegion(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          key: ValueKey('stack key ${widget.id}'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                widget.label,
                maxLines: 1,
                softWrap: false,
                style: AmalfiType.caption(
                  color: colors.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The content of the unit picker: a search field, a chip per category, the units with the
/// current one checked.
class UnitPicker extends StatefulWidget {
  const UnitPicker({
    super.key,
    required this.current,
    required this.language,
    required this.onChosen,
    this.width = 224,
  });

  final ConvertUnit current;
  final String language;
  final ValueChanged<ConvertUnit> onChosen;
  final double width;

  @override
  State<UnitPicker> createState() => _UnitPickerState();
}

class _UnitPickerState extends State<UnitPicker> {
  late UnitCategory _category = widget.current.category;
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<UnitCategory> get _categories {
    final list = [...UnitCategory.values];
    list.sort(
      (a, b) => a.name(widget.language).compareTo(b.name(widget.language)),
    );
    return list;
  }

  List<ConvertUnit> get _units {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return _category.units;
    return [
      for (final u in allUnits)
        if (u.name(widget.language).toLowerCase().contains(q) ||
            u.en.toLowerCase().contains(q) ||
            u.symbol.toLowerCase().contains(q))
          u,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final units = _units;
    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmalfiSearchField(
            key: const ValueKey('unit search'),
            controller: _query,
            placeholder: l.searchUnits,
            width: widget.width,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onCleared: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _categories)
                _Chip(
                  key: ValueKey('category ${c.name('en')}'),
                  label: c.name(widget.language),
                  selected: c == _category && _query.text.trim().isEmpty,
                  onPressed: () => setState(() {
                    _category = c;
                    _query.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 1, child: ColoredBox(color: colors.lineSeparator)),
          SizedBox(
            height: 176,
            child: units.isEmpty
                ? Center(
                    child: Text(
                      l.noUnits,
                      style: AmalfiType.callout(color: colors.textSecondary),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final u in units)
                        _UnitRow(
                          key: ValueKey('unit ${u.id}'),
                          unit: u,
                          language: widget.language,
                          checked: u == widget.current,
                          onPressed: () => widget.onChosen(u),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? colors.calculator.operator
                : const Color(0xFF3A3B40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Text(
              label,
              maxLines: 1,
              style: AmalfiType.callout(color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    super.key,
    required this.unit,
    required this.language,
    required this.checked,
    required this.onPressed,
  });

  final ConvertUnit unit;
  final String language;
  final bool checked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name(language),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmalfiType.body(color: colors.textPrimary),
                      ),
                      Text(
                        unit.symbol,
                        maxLines: 1,
                        style: AmalfiType.caption(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (checked)
                  AmalfiSymbol(
                    'checkmark',
                    size: 16,
                    color: colors.calculator.operator,
                    fallback: Text(
                      '✓',
                      style: AmalfiType.body(color: colors.calculator.operator),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 1, child: ColoredBox(color: colors.lineSeparator)),
        ],
      ),
    );
  }
}
