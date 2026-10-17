import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// Window title and app name.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get appTitle;

  /// The basic mode (keypad with the four operations).
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get modeBasic;

  /// The scientific mode (functions, powers, trigonometry).
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get modeScientific;

  /// The programmer mode (integers in base 8, 10 and 16, bitwise operators).
  ///
  /// In en, this message translates to:
  /// **'Programmer'**
  String get modeProgrammer;

  /// Tooltip of the toolbar button that opens the mode menu.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get modeButton;

  /// Tooltip of the toolbar button for the history sidebar.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get sidebarButton;

  /// View menu: the history sidebar, and the labels of its sections and record menu.
  ///
  /// In en, this message translates to:
  /// **'Show History'**
  String get showHistory;

  /// No description provided for @hideHistory.
  ///
  /// In en, this message translates to:
  /// **'Hide History'**
  String get hideHistory;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// No description provided for @historyLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get historyLast30Days;

  /// No description provided for @historyOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get historyOlder;

  /// No description provided for @historyCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get historyCopy;

  /// No description provided for @historyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// Shown on the display when a calculation has no result (division by zero, root of a negative…).
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Tooltip of the 2nd key in the scientific mode.
  ///
  /// In en, this message translates to:
  /// **'Switch to the secondary functions of the keys (or hold Shift)'**
  String get secondTooltip;

  /// Small label on the display while angles are in radians.
  ///
  /// In en, this message translates to:
  /// **'Rad'**
  String get radiansIndicator;

  /// Programmer mode: button that hides the bit editor.
  ///
  /// In en, this message translates to:
  /// **'Hide binary'**
  String get hideBinary;

  /// Programmer mode: button that shows the bit editor again.
  ///
  /// In en, this message translates to:
  /// **'Show binary'**
  String get showBinary;

  /// Edit menu: copies the value on the display.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Edit menu: pastes a number into the calculator.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Key that clears everything (nothing typed yet). Keep it short: two letters.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get keyClearAll;

  /// Key that clears what was typed. One letter.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get keyClear;

  /// Menu bar: the Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// Menu bar: the View menu.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// Menu bar: the Window menu.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// Menu bar: the Help menu.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// View menu: submenu with the number of decimals results show (0–15).
  ///
  /// In en, this message translates to:
  /// **'Decimal Places'**
  String get decimalPlaces;

  /// View menu: stop grouping digits by thousands.
  ///
  /// In en, this message translates to:
  /// **'Hide Thousands Separators'**
  String get hideThousands;

  /// View menu: group digits by thousands again.
  ///
  /// In en, this message translates to:
  /// **'Show Thousands Separators'**
  String get showThousands;

  /// Mode menu and View menu: turn on unit conversion.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get menuConvert;

  /// Mode menu and View menu: turn on reverse Polish notation.
  ///
  /// In en, this message translates to:
  /// **'RPN Mode'**
  String get menuRpn;

  /// Accessibility label of the pop-up that picks the unit of the typed value.
  ///
  /// In en, this message translates to:
  /// **'From unit'**
  String get fromUnit;

  /// Accessibility label of the pop-up that picks the unit of the result.
  ///
  /// In en, this message translates to:
  /// **'To unit'**
  String get toUnit;

  /// Tooltip of the button that swaps the two units.
  ///
  /// In en, this message translates to:
  /// **'Swap units'**
  String get swapUnits;

  /// Placeholder of the unit picker's search field.
  ///
  /// In en, this message translates to:
  /// **'Search units'**
  String get searchUnits;

  /// Shown when the unit search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No units found'**
  String get noUnits;

  /// Tooltip of the RPN key x⇄y.
  ///
  /// In en, this message translates to:
  /// **'Swap x and y'**
  String get stackSwap;

  /// Tooltip of the RPN key R↓.
  ///
  /// In en, this message translates to:
  /// **'Roll the stack down'**
  String get stackRollDown;

  /// Tooltip of the RPN key R↑.
  ///
  /// In en, this message translates to:
  /// **'Roll the stack up'**
  String get stackRollUp;

  /// Label of the RPN key that drops x.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get stackDrop;

  /// Tooltip of the RPN key that drops x.
  ///
  /// In en, this message translates to:
  /// **'Drop x'**
  String get stackDropTip;

  /// Title of the first-launch popover over the Mode button.
  ///
  /// In en, this message translates to:
  /// **'Mode menu'**
  String get tipTitle;

  /// Text of the first-launch popover.
  ///
  /// In en, this message translates to:
  /// **'Switch between Basic, Scientific and Programmer, convert units or turn on RPN.'**
  String get tipBody;

  /// Button of the first-launch popover.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tipDismiss;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
