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
  String get showHistory => 'Show History';

  @override
  String get hideHistory => 'Hide History';

  @override
  String get historyToday => 'Today';

  @override
  String get historyLast30Days => 'Last 30 days';

  @override
  String get historyOlder => 'Older';

  @override
  String get historyCopy => 'Copy';

  @override
  String get historyDelete => 'Delete';

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

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuView => 'View';

  @override
  String get menuWindow => 'Window';

  @override
  String get menuHelp => 'Help';

  @override
  String get decimalPlaces => 'Decimal Places';

  @override
  String get hideThousands => 'Hide Thousands Separators';

  @override
  String get showThousands => 'Show Thousands Separators';

  @override
  String get menuConvert => 'Convert';

  @override
  String get menuRpn => 'RPN Mode';

  @override
  String get fromUnit => 'From unit';

  @override
  String get toUnit => 'To unit';

  @override
  String get swapUnits => 'Swap units';

  @override
  String get searchUnits => 'Search units';

  @override
  String get noUnits => 'No units found';

  @override
  String get stackSwap => 'Swap x and y';

  @override
  String get stackRollDown => 'Roll the stack down';

  @override
  String get stackRollUp => 'Roll the stack up';

  @override
  String get stackDrop => 'Drop';

  @override
  String get stackDropTip => 'Drop x';

  @override
  String get tipTitle => 'Mode menu';

  @override
  String get tipBody =>
      'Switch between Basic, Scientific and Programmer, convert units or turn on RPN.';

  @override
  String get tipDismiss => 'Got it';
}
