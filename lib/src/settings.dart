// What the app keeps between launches, in `$XDG_CONFIG_HOME/calculator/settings.json`: whether
// the first-launch tip over the Mode button was already shown.

import 'dart:convert';
import 'dart:io';

class AppSettings {
  AppSettings(this.path);

  factory AppSettings.forUser(Map<String, String> env) {
    final config = env['XDG_CONFIG_HOME'] ?? '${env['HOME'] ?? '.'}/.config';
    return AppSettings('$config/calculator/settings.json')..load();
  }

  /// The file; null keeps everything in memory (tests).
  final String? path;

  bool tipShown = false;

  void load() {
    final p = path;
    if (p == null) return;
    try {
      final file = File(p);
      if (!file.existsSync()) return;
      final json = jsonDecode(file.readAsStringSync());
      if (json is Map) tipShown = json['tipShown'] == true;
    } on FileSystemException {
      // Unreadable: start with the defaults.
    } on FormatException {
      // Not JSON: the next save rewrites it.
    }
  }

  void save() {
    final p = path;
    if (p == null) return;
    try {
      final file = File(p);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({'tipShown': tipShown}));
    } on FileSystemException {
      // A read-only home: the app keeps working.
    }
  }
}
