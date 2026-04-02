import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pl'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pl, this message translates to:
  /// **'Schroniskowy Tracker Spacerów'**
  String get appTitle;

  /// No description provided for @navOverview.
  ///
  /// In pl, this message translates to:
  /// **'Przegląd'**
  String get navOverview;

  /// No description provided for @navPlanner.
  ///
  /// In pl, this message translates to:
  /// **'Planer'**
  String get navPlanner;

  /// No description provided for @navManage.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj'**
  String get navManage;

  /// No description provided for @walkOverview.
  ///
  /// In pl, this message translates to:
  /// **'Przegląd spacerów'**
  String get walkOverview;

  /// No description provided for @refresh.
  ///
  /// In pl, this message translates to:
  /// **'Odśwież'**
  String get refresh;

  /// No description provided for @dogs.
  ///
  /// In pl, this message translates to:
  /// **'Psy'**
  String get dogs;

  /// No description provided for @thisWeek.
  ///
  /// In pl, this message translates to:
  /// **'Ten tydzień'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In pl, this message translates to:
  /// **'Ostatni tydzień'**
  String get lastWeek;

  /// No description provided for @allDogs.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie psy'**
  String get allDogs;

  /// No description provided for @mostUrgentFirst.
  ///
  /// In pl, this message translates to:
  /// **'Najpilniejsze'**
  String get mostUrgentFirst;

  /// No description provided for @failedToLoadData.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się załadować danych'**
  String get failedToLoadData;

  /// No description provided for @retry.
  ///
  /// In pl, this message translates to:
  /// **'Ponów'**
  String get retry;

  /// No description provided for @walkPlanner.
  ///
  /// In pl, this message translates to:
  /// **'Planer spacerów'**
  String get walkPlanner;

  /// No description provided for @walkGroup.
  ///
  /// In pl, this message translates to:
  /// **'Grupa spacerowa'**
  String get walkGroup;

  /// No description provided for @solo.
  ///
  /// In pl, this message translates to:
  /// **'Solo'**
  String get solo;

  /// No description provided for @groupN.
  ///
  /// In pl, this message translates to:
  /// **'Grupa {n}'**
  String groupN(int n);

  /// No description provided for @addNote.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj notatkę'**
  String get addNote;

  /// No description provided for @noteFor.
  ///
  /// In pl, this message translates to:
  /// **'Notatka dla {name}'**
  String noteFor(String name);

  /// No description provided for @noteHintDog.
  ///
  /// In pl, this message translates to:
  /// **'np. szpital, zabrać do weterynarza'**
  String get noteHintDog;

  /// No description provided for @noteHintVolunteer.
  ///
  /// In pl, this message translates to:
  /// **'np. 10-13, tylko 2 psy'**
  String get noteHintVolunteer;

  /// No description provided for @remove.
  ///
  /// In pl, this message translates to:
  /// **'Usuń'**
  String get remove;

  /// No description provided for @cancel.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano'**
  String get saved;

  /// No description provided for @noWalksPlannedYet.
  ///
  /// In pl, this message translates to:
  /// **'Brak zaplanowanych spacerów'**
  String get noWalksPlannedYet;

  /// No description provided for @addFirstVolunteer.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pierwszego wolontariusza'**
  String get addFirstVolunteer;

  /// No description provided for @addVolunteer.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wolontariusza'**
  String get addVolunteer;

  /// No description provided for @addVolunteerButton.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wolontariusza'**
  String get addVolunteerButton;

  /// No description provided for @searchVolunteers.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj wolontariuszy...'**
  String get searchVolunteers;

  /// No description provided for @allVolunteersAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Wszyscy wolontariusze są już przypisani'**
  String get allVolunteersAssigned;

  /// No description provided for @noVolunteersMatch.
  ///
  /// In pl, this message translates to:
  /// **'Brak wolontariuszy pasujących do wyszukiwania'**
  String get noVolunteersMatch;

  /// No description provided for @addDog.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj psa'**
  String get addDog;

  /// No description provided for @selectDogs.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz psy'**
  String get selectDogs;

  /// No description provided for @tapToAddLongPress.
  ///
  /// In pl, this message translates to:
  /// **'Dotknij, aby dodać • Przytrzymaj, aby wybrać kilka'**
  String get tapToAddLongPress;

  /// No description provided for @allDogsAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie psy są już przypisane'**
  String get allDogsAssigned;

  /// No description provided for @addNDogs.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj {count} {count, plural, one{psa} few{psy} other{psów}}'**
  String addNDogs(int count);

  /// No description provided for @removeVolunteerTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć {name}?'**
  String removeVolunteerTitle(String name);

  /// No description provided for @removeVolunteerContent.
  ///
  /// In pl, this message translates to:
  /// **'Spowoduje to odpisanie {count} {count, plural, one{psa} few{psów} other{psów}}.'**
  String removeVolunteerContent(int count);

  /// No description provided for @failedToLoadPlan.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się załadować planu'**
  String get failedToLoadPlan;

  /// No description provided for @nVolunteersNDogs.
  ///
  /// In pl, this message translates to:
  /// **'{volunteers} wolontariuszy  •  {dogs}/{total} psów'**
  String nVolunteersNDogs(int volunteers, int dogs, int total);

  /// No description provided for @manage.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj'**
  String get manage;

  /// No description provided for @dogsTitleTab.
  ///
  /// In pl, this message translates to:
  /// **'Psy'**
  String get dogsTitleTab;

  /// No description provided for @volunteersTab.
  ///
  /// In pl, this message translates to:
  /// **'Wolontariusze'**
  String get volunteersTab;

  /// No description provided for @current.
  ///
  /// In pl, this message translates to:
  /// **'Obecne'**
  String get current;

  /// No description provided for @adopted.
  ///
  /// In pl, this message translates to:
  /// **'Adoptowane'**
  String get adopted;

  /// No description provided for @addDogButton.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj psa'**
  String get addDogButton;

  /// No description provided for @noDogsFound.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono psów'**
  String get noDogsFound;

  /// No description provided for @noAdoptedDogs.
  ///
  /// In pl, this message translates to:
  /// **'Brak adoptowanych psów'**
  String get noAdoptedDogs;

  /// No description provided for @editDog.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj psa'**
  String get editDog;

  /// No description provided for @name.
  ///
  /// In pl, this message translates to:
  /// **'Imię'**
  String get name;

  /// No description provided for @shelterId.
  ///
  /// In pl, this message translates to:
  /// **'ID schroniska'**
  String get shelterId;

  /// No description provided for @kennel.
  ///
  /// In pl, this message translates to:
  /// **'Boks'**
  String get kennel;

  /// No description provided for @kennelHint.
  ///
  /// In pl, this message translates to:
  /// **'3-cyfrowy numer'**
  String get kennelHint;

  /// No description provided for @nameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Imię jest wymagane'**
  String get nameRequired;

  /// No description provided for @shelterIdRequired.
  ///
  /// In pl, this message translates to:
  /// **'ID schroniska jest wymagane'**
  String get shelterIdRequired;

  /// No description provided for @kennelRequired.
  ///
  /// In pl, this message translates to:
  /// **'Boks jest wymagany'**
  String get kennelRequired;

  /// No description provided for @markAsAdopted.
  ///
  /// In pl, this message translates to:
  /// **'Oznacz jako adoptowanego'**
  String get markAsAdopted;

  /// No description provided for @restore.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć'**
  String get restore;

  /// No description provided for @add.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj'**
  String get edit;

  /// No description provided for @active.
  ///
  /// In pl, this message translates to:
  /// **'Aktywni'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In pl, this message translates to:
  /// **'Nieaktywni'**
  String get inactive;

  /// No description provided for @addVolunteerTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wolontariusza'**
  String get addVolunteerTitle;

  /// No description provided for @editVolunteer.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj wolontariusza'**
  String get editVolunteer;

  /// No description provided for @firstName.
  ///
  /// In pl, this message translates to:
  /// **'Imię'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko'**
  String get lastName;

  /// No description provided for @role.
  ///
  /// In pl, this message translates to:
  /// **'Rola'**
  String get role;

  /// No description provided for @firstNameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Imię jest wymagane'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko jest wymagane'**
  String get lastNameRequired;

  /// No description provided for @markAsInactive.
  ///
  /// In pl, this message translates to:
  /// **'Oznacz jako nieaktywnego'**
  String get markAsInactive;

  /// No description provided for @reactivate.
  ///
  /// In pl, this message translates to:
  /// **'Reaktywuj'**
  String get reactivate;

  /// No description provided for @noVolunteersFound.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono wolontariuszy'**
  String get noVolunteersFound;

  /// No description provided for @noInactiveVolunteers.
  ///
  /// In pl, this message translates to:
  /// **'Brak nieaktywnych wolontariuszy'**
  String get noInactiveVolunteers;

  /// No description provided for @dogFamiliarity.
  ///
  /// In pl, this message translates to:
  /// **'{name} — Znajomość psów'**
  String dogFamiliarity(String name);

  /// No description provided for @allGood.
  ///
  /// In pl, this message translates to:
  /// **'Dobrze idzie'**
  String get allGood;

  /// No description provided for @difficultButPossible.
  ///
  /// In pl, this message translates to:
  /// **'Trudny, ale możliwy'**
  String get difficultButPossible;

  /// No description provided for @noChance.
  ///
  /// In pl, this message translates to:
  /// **'Bez szans'**
  String get noChance;

  /// No description provided for @close.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij'**
  String get close;

  /// No description provided for @failed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się: {error}'**
  String failed(String error);

  /// No description provided for @failedToSave.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zapisać: {error}'**
  String failedToSave(String error);

  /// No description provided for @roleSenior.
  ///
  /// In pl, this message translates to:
  /// **'Wolontariusz'**
  String get roleSenior;

  /// No description provided for @roleIndependent.
  ///
  /// In pl, this message translates to:
  /// **'Samodzielny opiekun'**
  String get roleIndependent;

  /// No description provided for @roleSupporter.
  ///
  /// In pl, this message translates to:
  /// **'Wspierający'**
  String get roleSupporter;

  /// No description provided for @roleNew.
  ///
  /// In pl, this message translates to:
  /// **'Nowy'**
  String get roleNew;

  /// No description provided for @usingSystemTheme.
  ///
  /// In pl, this message translates to:
  /// **'Motyw systemowy'**
  String get usingSystemTheme;

  /// No description provided for @switchToLightMode.
  ///
  /// In pl, this message translates to:
  /// **'Przełącz na jasny motyw'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In pl, this message translates to:
  /// **'Przełącz na ciemny motyw'**
  String get switchToDarkMode;

  /// No description provided for @today.
  ///
  /// In pl, this message translates to:
  /// **'Dziś'**
  String get today;

  /// No description provided for @weekdayMon.
  ///
  /// In pl, this message translates to:
  /// **'Pon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In pl, this message translates to:
  /// **'Wt'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In pl, this message translates to:
  /// **'Śr'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In pl, this message translates to:
  /// **'Czw'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In pl, this message translates to:
  /// **'Pt'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In pl, this message translates to:
  /// **'Sob'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In pl, this message translates to:
  /// **'Niedz'**
  String get weekdaySun;

  /// No description provided for @monthJan.
  ///
  /// In pl, this message translates to:
  /// **'Sty'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In pl, this message translates to:
  /// **'Lut'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In pl, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In pl, this message translates to:
  /// **'Kwi'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In pl, this message translates to:
  /// **'Maj'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In pl, this message translates to:
  /// **'Cze'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In pl, this message translates to:
  /// **'Lip'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In pl, this message translates to:
  /// **'Sie'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In pl, this message translates to:
  /// **'Wrz'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In pl, this message translates to:
  /// **'Paź'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In pl, this message translates to:
  /// **'Lis'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In pl, this message translates to:
  /// **'Gru'**
  String get monthDec;

  /// No description provided for @kennelLabel.
  ///
  /// In pl, this message translates to:
  /// **'Boks: {kennel}'**
  String kennelLabel(String kennel);

  /// No description provided for @languageToggle.
  ///
  /// In pl, this message translates to:
  /// **'Zmień język'**
  String get languageToggle;
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
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
