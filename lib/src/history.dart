// The history of the calculations (kit `Apps/Calculator/History`, history.md): the records are
// kept newest first in `$XDG_DATA_HOME/calculator/history.json`, and the sidebar groups them
// by period. A record keeps the two texts it showed (expression and result), so it reads the
// same later whatever the locale or the decimal places have become.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/app_localizations.dart';

/// One calculation.
class HistoryRecord {
  const HistoryRecord(this.expression, this.result, this.time);

  final String expression;
  final String result;
  final DateTime time;

  Map<String, Object?> toJson() => {
    'expression': expression,
    'result': result,
    'time': time.millisecondsSinceEpoch,
  };

  static HistoryRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final expression = json['expression'];
    final result = json['result'];
    final time = json['time'];
    if (expression is! String || result is! String || time is! int) return null;
    return HistoryRecord(
      expression,
      result,
      DateTime.fromMillisecondsSinceEpoch(time),
    );
  }
}

/// The periods of the sidebar's section headers.
enum HistoryPeriod { today, last30Days, older }

class HistoryStore extends ChangeNotifier {
  HistoryStore([this.path]);

  /// `$XDG_DATA_HOME/calculator/history.json` (or `~/.local/share/…`).
  factory HistoryStore.forUser(Map<String, String> env) {
    final data = env['XDG_DATA_HOME'] ?? '${env['HOME'] ?? '.'}/.local/share';
    return HistoryStore('$data/calculator/history.json').._load();
  }

  /// The most records kept.
  static const int limit = 500;

  /// The file; null keeps the records in memory (tests).
  final String? path;

  /// Newest first.
  final List<HistoryRecord> records = [];

  void _load() {
    final p = path;
    if (p == null) return;
    try {
      final file = File(p);
      if (!file.existsSync()) return;
      final json = jsonDecode(file.readAsStringSync());
      if (json is! List) return;
      for (final item in json) {
        final record = HistoryRecord.fromJson(item);
        if (record != null) records.add(record);
      }
      records.sort((a, b) => b.time.compareTo(a.time));
      if (records.length > limit) records.removeRange(limit, records.length);
    } on FileSystemException {
      // Unreadable: start empty.
    } on FormatException {
      // Not JSON: start empty, the next save rewrites it.
    }
  }

  void _save() {
    final p = path;
    if (p == null) return;
    try {
      final file = File(p);
      file.parent.createSync(recursive: true);
      final tmp = File('$p.tmp');
      tmp.writeAsStringSync(jsonEncode([for (final r in records) r.toJson()]));
      tmp.renameSync(p);
    } on FileSystemException {
      // A read-only home: the history lives until the app closes.
    }
  }

  void add(String expression, String result, DateTime time) {
    records.insert(0, HistoryRecord(expression, result, time));
    if (records.length > limit) records.removeRange(limit, records.length);
    _save();
    notifyListeners();
  }

  void remove(HistoryRecord record) {
    if (!records.remove(record)) return;
    _save();
    notifyListeners();
  }

  /// The period [record] belongs to at [now].
  static HistoryPeriod periodOf(HistoryRecord record, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (!record.time.isBefore(today)) return HistoryPeriod.today;
    if (!record.time.isBefore(today.subtract(const Duration(days: 30)))) {
      return HistoryPeriod.last30Days;
    }
    return HistoryPeriod.older;
  }
}

/// Measures of the sidebar (kit master `Apps/Calculator/History`: 220 wide, the full window
/// height, running under the toolbar).
abstract final class HistoryMetrics {
  /// The window grows by this much to the right (history.md).
  static const double width = 220;
  static const double padding = 16;

  /// The first section header's rule row starts here (its 18 pt text sits 4 lower, at y 60).
  static const double topInset = 56;

  /// A header: 4 pt above its text, the 18 pt line and 26 to the first record.
  static const double headerHeight = 48;

  /// A record: expression (16), 4, result (20).
  static const double recordHeight = 40;

  /// Below a record: 12 to the separator, 1 for it and 11 to the next record.
  static const double recordGap = 24;

  /// Below the last record of a period: 12 to the next header's rule.
  static const double periodGap = 12;
}

sealed class _Row {
  const _Row();
}

class _Header extends _Row {
  const _Header(this.period);
  final HistoryPeriod period;
}

class _Record extends _Row {
  const _Record(this.record);
  final HistoryRecord record;
}

/// The sidebar: the records grouped by period, a context menu with Copy and Delete.
class HistorySidebar extends StatelessWidget {
  const HistorySidebar({super.key, required this.store, required this.now});

  final HistoryStore store;
  final DateTime Function() now;

  String _title(AppLocalizations l, HistoryPeriod p) => switch (p) {
    HistoryPeriod.today => l.historyToday,
    HistoryPeriod.last30Days => l.historyLast30Days,
    HistoryPeriod.older => l.historyOlder,
  };

  void _menu(BuildContext context, Offset at, HistoryRecord record) {
    final l = AppLocalizations.of(context);
    unawaited(
      showAmalfiMenu(
        context: context,
        position: at,
        entries: [
          AmalfiMenuAction(
            l.historyCopy,
            onSelected: () => unawaited(
              Clipboard.setData(ClipboardData(text: record.result)),
            ),
          ),
          AmalfiMenuAction(
            l.historyDelete,
            onSelected: () => store.remove(record),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final at = now();
    final rows = <_Row>[];
    HistoryPeriod? current;
    for (final r in store.records) {
      final period = HistoryStore.periodOf(r, at);
      if (period != current) {
        rows.add(_Header(period));
        current = period;
      }
      rows.add(_Record(r));
    }
    final line = colors.lineSeparator;
    Widget rule() => ColoredBox(color: line, child: const SizedBox(height: 1));
    return ColoredBox(
      color: colors.calculator.sidebar,
      // The sidebar's empty space (below the rows, in the top inset) moves the window.
      child: Stack(
        children: [
          const Positioned.fill(
            key: ValueKey('history drag area'),
            child: WindowDragArea(child: SizedBox.expand()),
          ),
          ListView.builder(
            key: const ValueKey('history list'),
            padding: const EdgeInsets.only(top: HistoryMetrics.topInset),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              final hasNext = i + 1 < rows.length;
              const side = EdgeInsets.symmetric(
                horizontal: HistoryMetrics.padding,
              );
              switch (row) {
                case _Header():
                  return Padding(
                    padding: side,
                    child: SizedBox(
                      height: HistoryMetrics.headerHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // The rule under the last record of the period above (kit: it is at the
                          // top of the header).
                          if (i > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: rule(),
                            ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 4,
                            child: Text(
                              _title(l, row.period),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AmalfiType.headline(
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                case _Record():
                  final next = hasNext ? rows[i + 1] : null;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onSecondaryTapUp: (d) =>
                        _menu(context, d.globalPosition, row.record),
                    child: Padding(
                      padding: side,
                      child: SizedBox(
                        height:
                            HistoryMetrics.recordHeight +
                            (next is _Record
                                ? HistoryMetrics.recordGap
                                : next != null
                                ? HistoryMetrics.periodGap
                                : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Kit: the operation in Callout (secondary), the result in Semibold
                            // 16 / 20, both right-aligned.
                            SizedBox(
                              height: 16,
                              child: Text(
                                row.record.expression,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AmalfiType.callout(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 20,
                              child: Text(
                                row.record.result,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AmalfiType.title3(
                                  color: colors.textPrimary,
                                ).copyWith(height: 20 / 16),
                              ),
                            ),
                            if (next is _Record) ...[
                              const SizedBox(height: 12),
                              rule(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}
