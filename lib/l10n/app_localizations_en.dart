// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calculator';

  @override
  String get modeBasic => 'Basic';

  @override
  String get modeScientific => 'Scientific';

  @override
  String get modeProgrammer => 'Programmer';

  @override
  String get modeButton => 'Mode';

  @override
  String get sidebarButton => 'History';

  @override
  String get error => 'Error';

  @override
  String get secondTooltip =>
      'Switch to the secondary functions of the keys (or hold Shift)';

  @override
  String get radiansIndicator => 'Rad';

  @override
  String get hideBinary => 'Hide binary';

  @override
  String get showBinary => 'Show binary';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get keyClearAll => 'AC';

  @override
  String get keyClear => 'C';
}
