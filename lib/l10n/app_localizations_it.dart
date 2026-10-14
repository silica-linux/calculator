// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Calcolatrice';

  @override
  String get modeBasic => 'Base';

  @override
  String get modeScientific => 'Scientifica';

  @override
  String get modeProgrammer => 'Programmatore';

  @override
  String get modeButton => 'Modalità';

  @override
  String get sidebarButton => 'Cronologia';

  @override
  String get error => 'Errore';

  @override
  String get secondTooltip =>
      'Passa alle funzioni secondarie dei tasti (anche tenendo premuto Maiuscole)';

  @override
  String get radiansIndicator => 'Rad';

  @override
  String get hideBinary => 'Nascondi binario';

  @override
  String get showBinary => 'Mostra binario';

  @override
  String get copy => 'Copia';

  @override
  String get paste => 'Incolla';

  @override
  String get keyClearAll => 'AC';

  @override
  String get keyClear => 'C';
}
